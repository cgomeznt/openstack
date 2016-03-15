#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

# Respaldo del hosts
cp -dp /etc/hosts /etc/hosts.out

# Modificamos el hosts
sed -e "
/^127.0.1.1/s/^/\#/
/^127.0.0.1/s/^/\#/" -i /etc/hosts

echo "
10.0.0.11	controller
10.0.0.21	network
10.0.0.31	compute1" >> /etc/hosts

echo "##############################################################################################################

Edite el archivo /etc/network/interfaces para que lo configure con algo como esto:

# loopback
auto lo
iface lo inet loopback

# primary interface
auto eth0
iface eth0 inet static
  address 10.0.0.11
  netmask 255.255.255.0

auto eth1
iface eth1 inet manual
  up ip link set dev \$IFACE up
  down ip link set dev \$IFACE down

Se edito el archivo /etc/hosts y se creo un respaldo /etc/hosts.out

10.0.0.11	controller
10.0.0.21	network
10.0.0.31	compute1

Si tiene mas maquinas agreguelas aqui de forma manual en el  /etc/hosts .

Despues 'ifdown --exclude=lo -a && sudo ifup --exclude=lo -a'.

Hacemos un test del servidor con './openstack_network_test.sh'

###############################################################################################################"
