#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

echo -e "
##############################################################################################

	Este script unicamente realiza un reinicio de los distintos componentes de nova

##############################################################################################
"

# Detener los servicios
service nova-api stop
sleep 6
service nova-cert stop
sleep 6
service nova-consoleauth stop
sleep 6
service nova-scheduler stop
sleep 6
service nova-conductor stop
sleep 6
service nova-novncproxy stop
sleep 6

# Iniciamos los servicios
service nova-api start
sleep 6
service nova-cert start
sleep 6
service nova-consoleauth start
sleep 6
service nova-scheduler start
sleep 6
service nova-conductor start
sleep 6
service nova-novncproxy start
sleep 6
