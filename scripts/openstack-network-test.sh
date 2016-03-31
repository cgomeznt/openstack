#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ ! -f ./.networking ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-networking.sh'

##################################################################################################
"
exit 1
fi

# Hacemos los test de conectividad
echo  " " 
echo -e '\e[33;1m Haciendo ping al nodo controller \e[m'
ping -c 4 controller
echo " " 
echo -e '\e[33;1m Haciendo ping al nodo network \e[m'
ping -c 4 network
echo " " 
echo -e '\e[33;1m Haciendo ping al nodo compute1 \e[m'
ping -c 4 compute1
echo " " 
echo -e '\e[33;1m Haciendo ping a openstack.org \e[m'
ping -c 4 openstack.org

touch ./.network-test

echo "
###############################################################################################################

Debe ver las respuestas de los ping al controller, network, compute y openstack.org, si ve algo malo no continue 
y solvente la falla. Siempre este muy pendiente del gateway, de los DNS y del NTP

Ejecute ahora '. ./openstack-server-test.sh'

###############################################################################################################
"
