
¿Cómo implementar OpenStack Cloud privado en CentOS? OpenStack es una popular plataforma de software libre y de código abierto para construir nubes públicas y privadas. Puede tener una OpenStack Cloud todo en uno ejecutándose en CentOS 7 en minutos usando la utilidad de instalación Packstack. Después de la implementación, puede agregar más nodos a su nube OpenStack, si lo desea.

https://www.rdoproject.org/install/adding-a-compute-node/

En esta configuración, crearemos una nube OpenStack usando Packstack en CentOS con los siguientes servicios.

* Cinder – Block storage service
* Neutron – Networking service
* Nova – Compute
* Swift – Object storage service
* Keystone – Identity Service
* Heat – Orchestration Service
* Glance – image service
* Horizon – Dashboard
* Magnum -Container service

Utilizaremos VirtualBox para este laboratorio con una VM en CentOS 7

	Memoria:	2018
	CPU:	4 de Intel(R) Core(TM) i5 CPU 650 @ 3.20GHz
	Discos:	3 x 50G SATA
	Network: 1GB

# grep -c ^processor /proc/cpuinfo 
4

# free -h
              total        used        free      shared  buff/cache   available
Mem:           1,8G        102M        1,6G        8,3M        141M        1,6G
Swap:          819M          0B        819M

# lsblk 
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   50G  0 disk 
├─sda1            8:1    0  500M  0 part /boot
├─sda2            8:2    0  7,5G  0 part 
│ ├─centos-root 253:0    0 47,7G  0 lvm  /
│ └─centos-swap 253:1    0  820M  0 lvm  [SWAP]
└─sda3            8:3    0   42G  0 part 
  └─centos-root 253:0    0 47,7G  0 lvm  /
sdb               8:16   0   50G  0 disk 
sdc               8:32   0   50G  0 disk 
sr0              11:0    1 1024M  0 rom  

# ip link  show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP mode DEFAULT qlen 1000
    link/ether 08:00:27:9d:8d:0b brd ff:ff:ff:ff:ff:ff


Paso 1: cumplir los requisitos de configuración
+++++++++++++++++++++++++++++++++++++++++++++++++++


Desactivaremos firewalld, NetworkManager y SELinux.::

	systemctl disable --now firewalld NetworkManager
	setenforce 0
	sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config


Establece el nombre de host de tu servidor.::

	hostnamectl set-hostname openstackcloud.example.com --static


Finalmente, actualice su sistema e instale las utilidades básicas.::

	yum -y update
	yum -y install vim wget curl telnet bash-completion
	reboot

Paso 2: Instalar paquetes Packstack
+++++++++++++++++++++++++++++++++++++++

Agregue el repositorio RDO (RPM Distribution of OpenStack) utilizando los comandos a continuación.::

	--- OpenStack Stein ----
	$ sudo yum install -y centos-release-openstack-stein

	--- OpenStack Rocky ----
	$ sudo yum install -y centos-release-openstack-rocky

Nosotros vamos a utilizar Stein porque aun esta en Mantenimiento hasta el 2019-04-10 y es Extended Maintenance estimated 2020-10-10

Si sigue este artículo cuando hay una versión más reciente de Openstack, reemplace stein o rocky con el nombre de la versión. Puede ver las versiones en este link

https://releases.openstack.org/

Una vez que se ha agregado el repositorio, instale el paquete packstack para CentOS.::

	yum install -y openstack-packstack

Paso 3: crea un archivo de respuestas packstack
+++++++++++++++++++++++++++++++++++++++++++++++


Necesitamos generar un archivo de configuración que se utilizará para instalar OpenStack Cloud con Packstack. Este archivo tiene información como servicios para instalar, configuración de almacenamiento, redes e.t.c.::

	$ packstack --gen-answer-file /root/answers.txt
	Packstack changed given value  to required value /root/.ssh/id_rsa


Abra el archivo de configuración generado y edítelo para adaptarlo a la instalación deseada. Estos son mis parámetros establecidos.::

	CONFIG_NTP_SERVERS=0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org
	CONFIG_CONTROLLER_HOST=192.168.10.10
	CONFIG_COMPUTE_HOSTS=192.168.10.10
	CONFIG_NETWORK_HOSTS=192.168.10.10
	CONFIG_STORAGE_HOST=192.168.10.10
	CONFIG_KEYSTONE_ADMIN_PW=b29e883d82dd45f8
	CONFIG_SWIFT_STORAGES=/dev/sdc2
	CONFIG_PROVISION_DEMO=n
	CONFIG_HEAT_INSTALL=y
	CONFIG_HEAT_CFN_INSTALL=y
	CONFIG_CEILOMETER_INSTALL=y
	CONFIG_MAGNUM_INSTALL=y
	CONFIG_LBAAS_INSTALL=y
	CONFIG_CINDER_VOLUMES_CREATE=n
	CONFIG_NOVA_SCHED_RAM_ALLOC_RATIO=3.0
	CONFIG_NOVA_LIBVIRT_VIRT_TYPE=%{::default_hypervisor}
	CONFIG_HORIZON_SSL=n


El almacenamiento de Cinder y Swift estará en mi dispositivo de bloque /dev/sdc.::

	parted -s -a optimal -- /dev/sdc mklabel gpt
	parted -s -a optimal -- /dev/sdc mkpart primary 0% 70%
	parted -s -a optimal -- /dev/sdc mkpart primary 70% 100%


Para Cinder, crearé un grupo de Volumen LVM separado que use /dev/sdc1.::

	$ pvcreate /dev/sdc1
	Physical volume "/dev/sdc1" successfully created. 

	$ vgcreate cinder-volumes /dev/sdc1
	Volume group "cinder-volumes" successfully created

	$ lvcreate -l 100%FREE -T cinder-volumes/cinder-volumes-pool
	Thin pool volume with chunk size 256.00 KiB can address at most 63.25 TiB of data.
	  Logical volume "cinder-volumes-pool" created.


El almacenamiento Swift se ubicará en una partición /dev/sdc2. Vamos a crear un sistema de archivos en él.::

	sudo mkfs.xfs /dev/sdc2

Paso 4: Instale OpenStack con packstack
++++++++++++++++++++++++++++++++++++++++

Ahora que tenemos un archivo de respuestas para usar, podemos arrancar un OpenStack Cloud usando la línea de comando packstack.::

	packstack --answer-file /root/answers.txt --timeout=1500 | tee packstrack-output.txt


Vea a continuación la salida de instalación.::

	Welcome to the Packstack setup utility

	The installation log file is available at: /var/tmp/packstack/20190710-211124-ZVhc4m/openstack-setup.log

	Installing:
	Clean Up                                             [ DONE ]
	Discovering ip protocol version                      [ DONE ]
	Setting up ssh keys                                  [ DONE ]
	Preparing servers                                    [ DONE ]
	Pre installing Puppet and discovering hosts' details [ DONE ]
	Preparing pre-install entries                        [ DONE ]
	Setting up CACERT                                    [ DONE ]
	Preparing AMQP entries                               [ DONE ]
	Preparing MariaDB entries                            [ DONE ]
	Fixing Keystone LDAP config parameters to be undef if empty[ DONE ]
	Preparing Keystone entries                           [ DONE ]
	Preparing Glance entries                             [ DONE ]
	Checking if the Cinder server has a cinder-volumes vg[ DONE ]
	Preparing Cinder entries                             [ DONE ]
	Preparing Nova API entries                           [ DONE ]
	Creating ssh keys for Nova migration                 [ DONE ]
	Gathering ssh host keys for Nova migration           [ DONE ]
	Preparing Nova Compute entries                       [ DONE ]
	Preparing Nova Scheduler entries                     [ DONE ]
	Preparing Nova VNC Proxy entries                     [ DONE ]
	Preparing OpenStack Network-related Nova entries     [ DONE ]
	Preparing Nova Common entries                        [ DONE ]
	Preparing Neutron LBaaS Agent entries                [ DONE ]
	Preparing Neutron API entries                        [ DONE ]
	Preparing Neutron L3 entries                         [ DONE ]
	Preparing Neutron L2 Agent entries                   [ DONE ]
	Preparing Neutron DHCP Agent entries                 [ DONE ]
	Preparing Neutron Metering Agent entries             [ DONE ]
	Checking if NetworkManager is enabled and running    [ DONE ]
	Preparing OpenStack Client entries                   [ DONE ]
	Preparing Horizon entries                            [ DONE ]
	Preparing Swift builder entries                      [ DONE ]
	Preparing Swift proxy entries                        [ DONE ]
	Preparing Swift storage entries                      [ DONE ]
	Preparing Heat entries                               [ DONE ]
	Preparing Heat CloudFormation API entries            [ DONE ]
	Preparing Gnocchi entries                            [ DONE ]
	Preparing Redis entries                              [ DONE ]
	Preparing Ceilometer entries                         [ DONE ]
	Preparing Aodh entries                               [ DONE ]
	Adding Magnum manifest entries                       [ DONE ]
	Preparing Puppet manifests                           [ DONE ]
	Copying Puppet modules and manifests                 [ DONE ]
	Applying 192.168.10.10_controller.pp
	192.168.10.10_controller.pp:                         [ DONE ]
	Applying 192.168.10.10_network.pp
	192.168.10.10_network.pp:                            [ DONE ]
	Applying 192.168.10.10_compute.pp
	192.168.10.10_compute.pp:                            [ DONE ]
	Applying Puppet manifests                            [ DONE ]
	Finalizing                                           [ DONE ]

	 **** Installation completed successfully ******

	Additional information:
	 * Time synchronization installation was skipped. Please note that unsynchronized time on server instances might be problem for some OpenStack components.
	 * File /root/keystonerc_admin has been created on OpenStack client host 192.168.10.10. To use the command line tools you need to source the file.
	 * To access the OpenStack Dashboard browse to http://192.168.10.10/dashboard .
	Please, find your login credentials stored in the keystonerc_admin in your home directory.
	 * Because of the kernel update the host 192.168.10.10 requires reboot.
	 * The installation log file is available at: /var/tmp/packstack/20190710-211124-ZVhc4m/openstack-setup.log
	 * The generated manifests are available at: /var/tmp/packstack/20190710-211124-ZVhc4m/manifests


Paso 5: Configurar OpenStack Networking
++++++++++++++++++++++++++++++++++++++++

Cree un puente OVS externo en su interfaz.::

	$ vi /etc/sysconfig/network-scripts/ifcfg-eno1
	DEVICE=eno1
	ONBOOT=yes
	TYPE=OVSPort
	DEVICETYPE=ovs
	OVS_BRIDGE=br-ex 

	$ vi /etc/sysconfig/network-scripts/ifcfg-br-ex
	DEVICE=br-ex
	BOOTPROTO=none
	ONBOOT=yes
	TYPE=OVSBridge
	DEVICETYPE=ovs
	USERCTL=yes
	PEERDNS=yes
	IPV6INIT=no
	IPADDR=192.168.10.10
	NETMASK=255.255.255.0
	GATEWAY=192.168.10.1
	DNS1=192.168.10.1

Mueva su ruta estática para la interfaz configurada a br-ex.::

	mv /etc/sysconfig/network-scripts/route-eno1 /etc/sysconfig/network-scripts/route-br-ex


Agregue la interfaz física de red al puente br-ex en Open vSwitch.::

	ovs-vsctl add-port br-ex eno1; systemctl restart network.service


Se pueden configurar puentes adicionales de manera similar. Deberá configurar Open vSwitch con las asignaciones correctas.::

	$ vi /etc/neutron/plugins/ml2/openvswitch_agent.ini 
	bridge_mappings=extnet:br-ex

Restart Nova services.::

	systemctl restart openstack-nova-compute
	systemctl restart openstack-nova-api
	systemctl restart openstack-nova-scheduler

Crear red privada OpenStack.::

	$ source keystonerc_admin
	$ openstack network create private

	+---------------------------+--------------------------------------+
	| Field                     | Value                                |
	+---------------------------+--------------------------------------+
	| admin_state_up            | UP                                   |
	| availability_zone_hints   |                                      |
	| availability_zones        |                                      |
	| created_at                | 2019-06-26T13:44:43Z                 |
	| description               |                                      |
	| dns_domain                | None                                 |
	| id                        | e406e76f-e89d-42a2-bab1-9c883b2e49aa |
	| ipv4_address_scope        | None                                 |
	| ipv6_address_scope        | None                                 |
	| is_default                | False                                |
	| is_vlan_transparent       | None                                 |
	| mtu                       | 1450                                 |
	| name                      | private                              |
	| port_security_enabled     | True                                 |
	| project_id                | d16dda64b73945898eebbd5be9572612     |
	| provider:network_type     | vxlan                                |
	| provider:physical_network | None                                 |
	| provider:segmentation_id  | 82                                   |
	| qos_policy_id             | None                                 |
	| revision_number           | 2                                    |
	| router:external           | Internal                             |
	| segments                  | None                                 |
	| shared                    | False                                |
	| status                    | ACTIVE                               |
	| subnets                   |                                      |
	| tags                      |                                      |
	| updated_at                | 2019-06-26T13:44:43Z                 |
	+---------------------------+--------------------------------------+

	$ openstack subnet create --network private --allocation-pool \
	start=10.1.1.50,end=10.1.1.200 --dns-nameserver 8.8.8.8 \
	--subnet-range 10.1.1.0/24 private_subnet

	+-------------------+--------------------------------------+
	| Field             | Value                                |
	+-------------------+--------------------------------------+
	| allocation_pools  | 10.1.1.50-10.1.1.200                 |
	| cidr              | 10.1.1.0/24                          |
	| created_at        | 2019-06-26T13:48:34Z                 |
	| description       |                                      |
	| dns_nameservers   | 8.8.8.8                              |
	| enable_dhcp       | True                                 |
	| gateway_ip        | 10.1.1.1                             |
	| host_routes       |                                      |
	| id                | 76ff61dd-0438-4848-a611-f4b4de070164 |
	| ip_version        | 4                                    |
	| ipv6_address_mode | None                                 |
	| ipv6_ra_mode      | None                                 |
	| name              | private_subnet                       |
	| network_id        | e406e76f-e89d-42a2-bab1-9c883b2e49aa |
	| project_id        | d16dda64b73945898eebbd5be9572612     |
	| revision_number   | 0                                    |
	| segment_id        | None                                 |
	| service_types     |                                      |
	| subnetpool_id     | None                                 |
	| tags              |                                      |
	| updated_at        | 2019-06-26T13:48:34Z                 |
	+-------------------+--------------------------------------+


Crea una red pública.::

	$ openstack network create --provider-network-type flat \
	--provider-physical-network extnet --external public

	+---------------------------+--------------------------------------+
	| Field                     | Value                                |
	+---------------------------+--------------------------------------+
	| admin_state_up            | UP                                   |
	| availability_zone_hints   |                                      |
	| availability_zones        |                                      |
	| created_at                | 2019-06-26T16:35:43Z                 |
	| description               |                                      |
	| dns_domain                | None                                 |
	| id                        | 900b1ede-3e62-4d73-88d3-b28c129a6bb6 |
	| ipv4_address_scope        | None                                 |
	| ipv6_address_scope        | None                                 |
	| is_default                | False                                |
	| is_vlan_transparent       | None                                 |
	| mtu                       | 1500                                 |
	| name                      | public                               |
	| port_security_enabled     | True                                 |
	| project_id                | d16dda64b73945898eebbd5be9572612     |
	| provider:network_type     | flat                                 |
	| provider:physical_network | extnet                               |
	| provider:segmentation_id  | None                                 |
	| qos_policy_id             | None                                 |
	| revision_number           | 2                                    |
	| router:external           | External                             |
	| segments                  | None                                 |
	| shared                    | False                                |
	| status                    | ACTIVE                               |
	| subnets                   |                                      |
	| tags                      |                                      |
	| updated_at                | 2019-06-26T16:35:43Z                 |
	+---------------------------+--------------------------------------+

	$ openstack subnet create --network public \
	    --allocation-pool start=<startip>,end=<lastip> \
	    --no-dhcp \
	    --subnet-range <subnet>/27 public_subnet

Agregue un nuevo enrutador y configure las interfaces del enrutador.::

	$ openstack router create --no-ha router1

	+-------------------------+--------------------------------------+
	| Field                   | Value                                |
	+-------------------------+--------------------------------------+
	| admin_state_up          | UP                                   |
	| availability_zone_hints |                                      |
	| availability_zones      |                                      |
	| created_at              | 2019-06-26T16:36:54Z                 |
	| description             |                                      |
	| distributed             | False                                |
	| external_gateway_info   | None                                 |
	| flavor_id               | None                                 |
	| ha                      | False                                |
	| id                      | 188d5388-6f58-4387-8a13-018b9c2e81f4 |
	| name                    | router1                              |
	| project_id              | d16dda64b73945898eebbd5be9572612     |
	| revision_number         | 0                                    |
	| routes                  |                                      |
	| status                  | ACTIVE                               |
	| tags                    |                                      |
	| updated_at              | 2019-06-26T16:36:54Z                 |
	+-------------------------+--------------------------------------+

	$ openstack router set --external-gateway public router1
	$ openstack router add subnet router1 private_subnet
	$ ip netns show
	qrouter-188d5388-6f58-4387-8a13-018b9c2e81f4 (id: 1)
	qdhcp-e406e76f-e89d-42a2-bab1-9c883b2e49aa (id: 0)


Paso 6: Configurar Cinder
+++++++++++++++++++++++++++

Configure Cinder para usar el volumen LVM configurado.::

	$ vi /etc/cinder/cinder.conf
	enabled_backends=lvm
	volume_clear = none

	[lvm]
	volume_backend_name=lvm
	volume_driver=cinder.volume.drivers.lvm.LVMVolumeDriver
	iscsi_ip_address=192.168.10.10
	iscsi_helper=lioadm
	volume_group=cinder-volumes
	volumes_dir=/var/lib/cinder/volumes


Debe reiniciar los servicios de Cinder después del cambio.::

	systemctl restart openstack-cinder-volume
	systemctl restart openstack-cinder-api


Paso 7: crear sabores y grupos de seguridad
++++++++++++++++++++++++++++++++++++++++++++++

Agreguemos sabores OpenStack::

	openstack flavor create --id 0 --ram 1024  --vcpus  1 --swap 2048  --disk 10    m1.tiny
	openstack flavor create --id 1 --ram 2048  --vcpus  1 --swap 4096  --disk 20    m1.small
	openstack flavor create --id 2 --ram 4096  --vcpus  2 --swap 8192  --disk 40    m1.medium
	openstack flavor create --id 3 --ram 8192  --vcpus  4 --swap 8192  --disk 80    m1.large
	openstack flavor create --id 4 --ram 16384 --vcpus  8 --swap 8192  --disk 160   m1.xlarge

Y grupo básico de seguridad::

	openstack security group create basic --description "Allow base ports"
	openstack security group rule create --protocol TCP --dst-port 22 --remote-ip 0.0.0.0/0 basic
	openstack security group rule create --protocol TCP --dst-port 80 --remote-ip 0.0.0.0/0 basic
	openstack security group rule create --protocol TCP --dst-port 443 --remote-ip 0.0.0.0/0 basic
	openstack security group rule create --protocol ICMP --remote-ip 0.0.0.0/0 basic

Paso 8: Cree una clave privada y agregue imágenes Glance
++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Cree una nueva clave para su cuenta o use una existente.::

	$ ssh-keygen -q -N "" 
	$ openstack keypair create --public-key=~/.ssh/id_rsa.pub adminkey 
	+-------------+-------------------------------------------------+
	| Field       | Value                                           |
	+-------------+-------------------------------------------------+
	| fingerprint | 7a:44:0d:94:8a:c6:6d:fd:11:8e:20:42:e9:10:6f:9d |
	| name        | adminkey                                        |
	| user_id     | 4d1ab48579084cda924ca40a8ce0766b                |
	+-------------+-------------------------------------------------+


Para obtener imágenes de Glance, consulte nuestra guía anterior:

https://computingforgeeks.com/adding-images-openstack-glance/


Acceso al panel de control de OpenStack
++++++++++++++++++++++++++++++++++++++

Para acceder al panel de OpenStack, vaya a http://openstackip/dashboard.



Sus credenciales de inicio de sesión se almacenan en el archivo keystonerc_admin en su directorio de inicio.

