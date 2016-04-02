!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi


if [ "$(hostname)" != "compute1" ]; then
echo "
##################################################################################################

Este script solo se debe ejecutar en el nodo compute1

##################################################################################################"
exit 1
fi


if [ ! -f ./.packages ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-package.sh'

##################################################################################################
"
exit 1
fi

if [ ! -f ./password-table.sh ] || [ ! -f ./admin-openrc.sh ];then
echo "
##################################################################################################

No puede hacer este paso debe asegurar que tenga los archvios
./password-table.sh y ./admin-openrc.sh

##################################################################################################
"
fi

# Instalamos los paquetes nova-compute sysfsutils
apt-get install nova-compute sysfsutils -y

sleep 5

# Creamos un respaldo del archivo de configuracion original
if [ -f /etc/nova/nova.conf.out ] ; then
echo "El archivo ya existe, por lo que se reestablecera y luego sera adaptado por este script"
cp -dp /etc/nova/nova.conf.out /etc/nova/nova.conf
else
cp -dp /etc/nova/nova.conf /etc/nova/nova.conf.out
fi

source ./password-table.sh

# Editamos el archivo /etc/glance/glance-api.conf para completar las siguientes acciones
echo -e "
[DEFAULT]
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
libvirt_use_virtio_for_bridges=True
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
enabled_apis=ec2,osapi_compute,metadata
# Tunning for manual
rpc_backend = rabbit
rabbit_host = controller
rabbit_password = $RABBIT_PASS
auth_strategy = keystone
my_ip = 10.0.0.31
vnc_enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = 10.0.0.31
novncproxy_base_url = http://controller:6080/vnc_auto.html
verbose = True
# Esto es solo para nova-network
#network_api_class = nova.network.api.API
#security_group_api = nova
#firewall_driver = nova.virt.libvirt.firewall.IptablesFirewallDriver
#network_manager = nova.network.manager.FlatDHCPManager
#network_size = 254
#allow_same_net_traffic = False
#multi_host = True
#send_arp_for_ha = True
#share_dhcp_address = True
#force_dhcp_release = True
#flat_network_bridge = br100
#flat_interface = INTERFACE_NAME
#public_interface = INTERFACE_NAME

[keystone_authtoken]
auth_uri = http://controller:5000/v2.0
identity_uri = http://controller:35357
admin_tenant_name = service
admin_user = nova
admin_password = $NOVA_PASS

[glance]
host = controller
" > /etc/nova/nova.conf

# Determinamos si este nodo soporte aceleracion de hardware para maquinas virtuales
if  [ "$(egrep -c '(vmx|svm)' /proc/cpuinfo)" != "0" ]; then
echo "
#################################################################################################

Su CPU soporta extensiones KVM. 

Realice las pruebas busque mas y vaya preparando el snmp

NOTA: /var/lib/nova/CA should be owned by nova
	
'source admin-openrc.sh && nova service-list'

##################################################################################################
"
else

# Si no soporta KVM lo emulamos
sed -e "
/^virt_type=kvm/s/^.*$/virt_type = qemu/
" -i /etc/nova/nova-compute.conf

echo "
##################################################################################################

Su CPU NO soporta extensiones KVM. deberia investigue antes de continuar

Usted puede modificar /etc/nova/nova-compute.conf (una vez instalado) para emular esta aceleracion:

[libvirt]
...
virt_type = qemu

NOTA: /var/lib/nova/CA should be owned by nova

##################################################################################################
"
fi

# Reiniciamos los servicios
service nova-compute restart

# Como esta configurado SQL por defecto, borramos la base de datos de SQLite
rm -f /var/lib/nova/nova.sqlite

touch ./.nova-compute

echo -e "
##############################################################################################

Realice las pruebas busque mas y vaya preparando el snmp
	
En el nodo controller ejecute 'source admin-openrc.sh && nova service-list' 

NOTA: /var/lib/nova/CA should be owned by nova

Ahora puede continuar con 'openstack-nova-network-compute.sh'

##############################################################################################
"

