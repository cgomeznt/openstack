!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ -f ./.nova-network ];then
echo "
##################################################################################################

Usted ya ejecuto este script debe continuar con 

'. ./openstack-launch-instance.sh' pero en el controller

##################################################################################################
"
exit 0
fi

if [ "$(hostname)" == "controller" ]; then 

if [ ! -f ./.nova-controller ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-nova-controller.sh'

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
exit 1
fi 

echo "
##################################################################################################

Se va ejecutar el procedimiento en el nodo controllador para activar nova-network

##################################################################################################
"

# Editamos el archivo /etc/nova/nova.conf para completar las siguientes acciones.
# no hacemos respaldo porque ya con openstack-nova-controller.sh lo hicimos y estas lineas fueron preparadas.
sed -e"
/^#network_api_class.*$/s/^.*$/network_api_class = nova.network.api.API/
/^#security_group_api.*$/s/^.*$/security_group_api = nova/
" -i /etc/nova/nova.conf

# Reiniciamos los servicios
service nova-api restart
sleep 6
service nova-scheduler restart
sleep 6
service nova-conductor restart
sleep 6

echo "
##################################################################################################

Debemos copiarnos el archivo password-table.sh que esta en el nodo controller (contiene los password) al nodo compute1
desde el nodo controller hacemos 'scp password-table.sh usuario@compute1:/tmp'

Ahora pasamos con el nodo compute1.
'. ./openstack-inicio.sh'
'. ./openstack-networking.sh'
'. ./openstack-network-test.sh'
'. ./openstack-server-test.sh'
'. ./openstack-ntp.sh'
'. ./openstack-packages.sh'
'. ./openstack-nova-compute.sh' 
'. ./openstack-nova-network.sh'y luego

Cuando termine con el nodo compute1 realice las pruebas desde el nodo controller 'source admin-openrc.sh && nova service-list'
debera ver ahi el servicio ahora de compute1
	
Luego en el nodo controller debe crear una infraestructura de red virtual

'source admin-openrc.sh'
'nova network-create demo-net --bridge br100 --multi-host T \
--fixed-range-v4 203.0.113.24/29'
'nova net-list'

##################################################################################################"

else

if [ ! -f ./.nova-compute ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-nova-compute.sh'

##################################################################################################
"
exit 1
fi

echo "
##################################################################################################

Se va ejecutar el procedimiento en el nodo compute para activar nova-network

##################################################################################################
"

# Instalamos los paquetes nova-network nova-api-metadata
apt-get install nova-network nova-api-metadata -y

# Editamos el archivo /etc/nova/nova.conf para completar las siguientes acciones
INTERFACE_NAME=$(cat /etc/network/interfaces | awk ' /manual/ {print $2}')
#$INTERFACE_NAME=$(sed -n 's/iface \(eth[0-9]\).*manual/\1/p' /etc/network/interfaces)

# no hacemos respaldo porque ya con openstack-nova-controller.sh lo hicimos y estas lineas fueron preparadas.
sed -e"
/^#network_api_class.*$/s/^.*$/network_api_class = nova.network.api.API/
/^#security_group_api.*$/s/^.*$/security_group_api = nova/
/^#firewall_driver.*$/s/^.*$/firewall_driver = nova.virt.libvirt.firewall.IptablesFirewallDriver/
/^#network_manager.*$/s/^.*$/network_manager = nova.network.manager.FlatDHCPManager/
/^#network_size.*$/s/^.*$/network_size = 254/
/^#allow_same_net_traffic.*$/s/^.*$/allow_same_net_traffic = False/
/^#multi_host.*$/s/^.*$/multi_host = True/
/^#send_arp_for_ha.*$/s/^.*$/send_arp_for_ha = True/
/^#share_dhcp_address.*$/s/^.*$/share_dhcp_address = True/
/^#force_dhcp_release.*$/s/^.*$/force_dhcp_release = True/
/^#flat_network_bridge.*$/s/^.*$/flat_network_bridge = br100/
/^#flat_interface.*$/s/^.*$/flat_interface = $INTERFACE_NAME /
/^#public_interface.*$/s/^.*$/public_interface = $INTERFACE_NAME /
" -i /etc/nova/nova.conf

# Reiniciamos los servicios
service nova-network restart
service nova-api-metadata restart

echo "
##################################################################################################

En el nodo controller debe crear una infraestructura de red virtual

'source admin-openrc.sh'
'nova network-create demo-net --bridge br100 --multi-host T \
--fixed-range-v4 10.0.3.24/29'
'nova net-list'

Puede ahora continuar con '. ./openstack-launch-instance'

##################################################################################################
"
fi

touch ./.nova-network

