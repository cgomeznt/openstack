#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

# Hacemos los test de conectividad
ping -c 4 controller
ping -c 4 network
ping -c 4 compute1
ping -c 4 openstack.org

echo "
###############################################################################################################

	Debe ver las respuestas de los ping al controller, network, compute y openstack.org, si ve algo malo no continue 
	y solvente la falla. Siempre este muy pendiente del gateway, de los DNS y del NTP

	Ejecute ahora '. ./openstack-server-test.sh'

###############################################################################################################
"
