#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ "$(hostname)" != "controller" ]; then
echo "
##################################################################################################

Este script solo se debe ejecutar en el nodo controller

##################################################################################################"
exit 1
fi

if [ -f ./.openstack-horizon ];then
echo "
##################################################################################################

Usted ya ejecuto este script debe continuar 



##################################################################################################
"
exit 0
fi

if [ ! -f ./.nova-network ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-.nova-network.sh'

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

source ./password-table.sh

# Instalamos el paquete de dashboard - nombre codigo Horizon
apt-get install openstack-dashboard -y

# Creamos un respaldo del archivo de configuracion original
if [ -f /etc/openstack-dashboard/local_settings.py.out ] ; then
echo "El archivo ya existe, por lo que se reestablecera y luego sera adaptado por este script"
cp -dp /etc/openstack-dashboard/local_settings.py.out /etc/openstack-dashboard/local_settings.py
else
cp -dp /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.out
fi


# Configurar el dashboard, editando  /etc/openstack-dashboard/local_settings.py
sed -e "
/^OPENSTACK_HOST.*$/s/^.*$/OPENSTACK_HOST = \"controller\"/
/^ALLOWED_HOSTS.*$/s/^.*$/ALLOWED_HOSTS = \[\'\*\'\, \]/
/^OPENSTACK_KEYSTONE_DEFAULT_ROLE.*$/s/^.*$/OPENSTACK_KEYSTONE_DEFAULT_ROLE = \"user\"/
/^TIME_ZONE.*$/s/^.*$/TIME_ZONE = \"UTC\"/
" -i  /etc/openstack-dashboard/local_settings.py

apt-get remove openstack-dashboard-ubuntu-theme -y

# Finalizamos la instalacion reiniciando el apache
echo "
##################################################################################################

Verificamos la operacion

Aceder al dashboard usando un navegado web http://controller/horizon 

Autentique usando las credenciales de admin o demo

para obtener la clave de admin seria en el nodo controller

'awk -F= '/ADMIN/ {print $2}' password-table.sh'


##################################################################################################"





