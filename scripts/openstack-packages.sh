#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ ! -f ./.ntp ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-server-test.sh'

##################################################################################################
"
exit 1
fi

# Habilitamos el repositorio de OpenStack June
apt-get install ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
"trusty-updates/juno main" > /etc/apt/sources.list.d/cloudarchive-juno.list

apt-get update && apt-get dist-upgrade -y

touch ./.packages

if [ "$(hostname)" == "controller" ]; then 
echo "
##################################################################################################

	Debes reiniciar el equipo

	Ahora ejecute '. ./openstack-database.sh'

##################################################################################################
"
else
echo "
##################################################################################################

	Debes reiniciar el equipo

	Ahora ejecute '. ./openstack-nova-compute.sh'

##################################################################################################
"
fi
