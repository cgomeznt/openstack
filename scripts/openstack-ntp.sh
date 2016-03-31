#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ ! -f ./.server-test ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-server-test.sh'

##################################################################################################
"
exit 1
fi

# Actualizamos los indices de los paquetes del apt
apt-get update

# Instalamos el servicio de NTP
apt-get install ntp -y

# Hacemos respaldo
if [ -f /etc/ntp.conf.out ]; then
cp -dp /etc/ntp.conf.out /etc/ntp.conf
else
cp -dp /etc/ntp.conf /etc/ntp.conf.out
fi

if [ "$(hostname)" == "controller" ]; then
sed -e "
/^server 0.*$/s/^.*$/server 0.ubuntu.pool.ntp.org iburst/
/^server 1.*$/s/^.*$/server 1.ubuntu.pool.ntp.org iburst/
/^server 2.*$/s/^.*$/server 2.ubuntu.pool.ntp.org iburst/
/^server 3.*$/s/^.*$/server 3.ubuntu.pool.ntp.org iburst/" -i /etc/ntp.conf
else
sed -e "
/server 0.*$/s/^.*$/server controller iburst/
/^server 1.*$/d
/^server 2.*$/d
/^server ntp.ubuntu.com/d
/^server 3.*$/d" -i /etc/ntp.conf
fi

if [ -f /var/lib/ntp/ntp.conf.dhcp ] ;then
	p/ntp.conf.dhcp
fi

service ntp restart

sleep 4

# verificamos 
ntpq -c peers

ntpq -c assoc

touch ./.ntp

echo "
##################################################################################################

Debe probar la configuracion de NTP con 'ntpq -c peers && ntpq -c assoc'
Si la configuracion del NTP esta correcta continue

Ahora ejecute '. ./openstack-openstack-packages.sh'

##################################################################################################
"
