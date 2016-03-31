!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ ! -f ./.glance ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-glance.sh'

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

if [ -f ./.nova-controller ];then
echo "
##################################################################################################

Usted ya ejecuto este script debe continuar con 

'. ./openstack-nova-network-controller.sh' si solo si, esta en el controller

##################################################################################################
"
exit 0
fi

source ./password-table.sh
source ./admin-openrc.sh

# Crear las credenciales de servicio
keystone user-create --name nova --pass $NOVA_PASS

# Agrega el role de admin para el usuario glance
keystone user-role-add --user nova --tenant service --role admin

# Crea el servicio glance del tipo image
keystone service-create --name nova --type compute \
--description "OpenStack Compute"

# Crea el Endpoint para el servicio glance
keystone endpoint-create \
--service-id $(keystone service-list | awk '/ compute / {print $2}') \
--publicurl http://controller:8774/v2/%\(tenant_id\)s \
--internalurl http://controller:8774/v2/%\(tenant_id\)s \
--adminurl http://controller:8774/v2/%\(tenant_id\)s \
--region regionOne

# Instalamos los paquetes nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient
apt-get install nova-api nova-cert nova-conductor nova-consoleauth \
nova-novncproxy nova-scheduler python-novaclient -y

sleep 5

# Creamos un respaldo del archivo de configuracion original
if [ -f /etc/nova/nova.conf.out ] ; then
echo "El archivo ya existe, por lo que se reestablecera y luego sera adaptado por este script"
cp -dp /etc/nova/nova.conf.out /etc/nova/nova.conf
else
cp -dp /etc/nova/nova.conf /etc/nova/nova.conf.out
fi

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
my_ip = 10.0.0.11
vncserver_listen = 10.0.0.11
vncserver_proxyclient_address = 10.0.0.11
verbose = True
# Esto es solo para nova-network
#network_api_class = nova.network.api.API
#security_group_api = nova

[database]
connection = mysql://nova:$NOVA_DBPASS@controller/nova

[keystone_authtoken]
auth_uri = http://controller:5000/v2.0
identity_uri = http://controller:35357
admin_tenant_name = service
admin_user = nova
admin_password = $NOVA_PASS

[glance]
host = controller
" > /etc/nova/nova.conf


# Poblamos la base de datos de nova
su -s /bin/sh -c "nova-manage db sync" nova

# Reiniciamos los servicios
service nova-api restart
sleep 6
service nova-cert restart
sleep 6
service nova-consoleauth restart
sleep 6
service nova-scheduler restart
sleep 6
service nova-conductor restart
sleep 6
service nova-novncproxy restart
sleep 6

# Como esta configurado SQL por defecto, borramos la base de datos de SQLite
rm -f /var/lib/nova/nova.sqlite

touch ./nova-controller

source admin-openrc.sh

nova service-list

touch ./.nova-controller

echo -e "
##############################################################################################

Realice las pruebas busque mas y vaya preparando el snmp

NOTA: /var/lib/nova/CA should be owned by nova

Ahora '. ./openstack-nova-network.sh'

Luego pasamos con el nodo compute 
'. ./openstack-inicio.sh'
'. ./openstack-networking.sh'
'. ./openstack-network-test.sh'
'. ./openstack-server-test.sh'
'. ./openstack-ntp.sh'
'. ./openstack-packages.sh'
'. ./openstack-nova-compute.sh' 
'. ./openstack-nova-network.sh'y luego

Cuando termine con el nodo compute realice las pruebas 'source admin-openrc.sh && nova service-list'
debera ver ahi el servicio ahora de compute1


##############################################################################################
"

