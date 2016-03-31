#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ ! -f ./.security ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-security.sh'

##################################################################################################
"
exit 1
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

touch ./.networking

echo "

Edite el archivo /etc/network/interfaces para que le quede como lo indica la guia de OpenStack y depende de la 
architectura seleccionada.

Para que la configuracion quede como esto:

------------------------En el controller------------------------
	# loopback
	auto lo
	iface lo inet loopback

	# The primary interface and manage network
	auto eth0
	iface eth0 inet static
	  address 10.0.0.11
	  netmask 255.255.255.0
------------------------En el network------------------------
	# loopback
	auto lo
	iface lo inet loopback

	# The primary interface and manage network
	auto eth0
	iface eth0 inet static
	  address 10.0.0.21
	  netmask 255.255.255.0

	auto eth1
	iface eth1 inet manual
	  up ip link set dev \$IFACE up
	  down ip link set dev \$IFACE down
------------------------En el compute1------------------------
	# loopback
	auto lo
	iface lo inet loopback

	# The primary interface and manage network
	auto eth0
	iface eth0 inet static
	  address 10.0.0.31
	  netmask 255.255.255.0

	auto eth1
	iface eth1 inet manual
	  up ip link set dev \$IFACE up
	  down ip link set dev \$IFACE down
------------------------------------------------------------------------

Se edito el archivo /etc/hosts y se creo un respaldo /etc/hosts.out

	10.0.0.11	controller
	10.0.0.21	network
	10.0.0.31	compute1

Si tiene mas maquinas agreguelas aqui de forma manual en el  /etc/hosts .

Despues 'ifdown --exclude=lo -a && sudo ifup --exclude=lo -a'.

Hacemos un test del servidor con '. ./openstack_network_test.sh'

###############################################################################################################"
