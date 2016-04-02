#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ "$(hostname)" == "controller" ]; then
if [ ! -f ./.security ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-security.sh'

##################################################################################################
"
exit 1
fi
fi

# Respaldo del hosts
if [ -f /etc/hosts.out ]; then
cp -dp /etc/hosts.out /etc/hosts
else
cp -dp /etc/hosts /etc/hosts.out
fi

echo "##############################################################################################################

Se creo un respaldo de /etc/hosts en /etc/hosts.out

##############################################################################################################"

# Modificamos el hosts
sed -e "
/^127.0.1.1/s/^/\#/
/^127.0.0.1/s/^/\#/" -i /etc/hosts

echo "
10.0.0.11	controller
10.0.0.21	network
10.0.0.31	compute1" >> /etc/hosts

# Respaldo del interface
if [ -f /etc/network/interfaces.out ]; then
cp -dp /etc/network/interfaces.out /etc/network/interfaces
else
cp -dp /etc/network/interfaces /etc/network/interfaces.out
fi

# Le asignamos las IPs correspondiente al controller y al compute1
if [ "$(hostname)" == "controller" ]; then
sed -e "
/^iface eth0 inet dhcp.*$/s/^.*$/iface eth0 inet static \n address 10.0.0.11 \n netmask 255.255.255.0/" -i /etc/network/interfaces
else
sed -e "
/eth1/d
/^iface eth0 inet dhcp.*$/s/^.*$/iface eth0 inet static \n address 10.0.0.31 \n netmask 255.255.255.0 \
\n\n # The external network interface \n \
auto eth1 \n \
iface eth1 inet manual \n \
up ip link set dev \$IFACE up\n \
down ip link set dev \$IFACE down \n/" -i /etc/network/interfaces
fi

# ifdown --exclude=lo -a && sudo ifup --exclude=lo -a
ifdown eth0 && ifup eth0
ifdown eth1 && ifup eth1

touch ./.networking

clear
echo "
###############################################################################################################
Se edito el archivo /etc/hosts y se creo un respaldo /etc/hosts.out, se agregaron estas lineas.

	10.0.0.11	controller
	10.0.0.21	network
	10.0.0.31	compute1

Se edito el archivo /etc/network/interfaces y se creo un respaldo /etc/network/interfaces.out, se modificaron estas lineas.

	auto eth0
	iface eth0 inet static 
	 address 10.0.0.11 
	 netmask 255.255.255.0

Hacemos un test del servidor con '. ./openstack_network_test.sh'

###############################################################################################################"
