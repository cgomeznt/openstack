#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi


if [ -f ./.launch-instance ];then
echo "
##################################################################################################

Usted ya ejecuto este script debe continuar con le recomendamos que lo haga manual o desde Horizon

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

# Generamos una llave
ssh-keygen

# Agregamos la llave publica al Enviroment de OpenStack
echo -e '\n\e[33;1m Pulse Enter para continuar...!!! \e[m'
nova keypair-add --pub-key ~/.ssh/id_rsa.pub demo-key

# Verificamos la llave publica que se haya agregara
echo -e '\n\e[33;1m Debe ver que se agregara una llave publica, llamada demo-key \e[m'
nova keypair-list

# Listamos los sabores disponibles
echo -e '\n\e[33;1m Flavors disponibles \e[m'
nova flavor-list

# Listamos las imagenes disponibles 
echo -e '\n\e[33;1m Images disponibles \e[m'
nova image-list
NAME_IMAGE=$(nova image-list | awk '/cirros/ {print $4}')

# Listamos las redes disponibles
echo -e '\n\e[33;1m Redes disponibles \e[m' 
nova net-list
DEMO_NET_ID=$(nova net-list | awk '/demo/ {print $2}')

# Listamos los grupos de seguridad disponibles
echo -e '\n\e[33;1m Grupos de seguridad disponibles \e[m' 
nova secgroup-list

# Lanzamos la instancia
nova boot --flavor m1.tiny --image $NAME_IMAGE --nic net-id=$DEMO_NET_ID \
  --security-group default --key-name demo-key demo-instance1

# Chequeamos el estatus de las instancias
echo -e '\n\e[33;1m Chequear el estatus de las instancias \e[m'

# Para haceder a la instancia usamos un consola virtual
echo -e '\n\e[33;1m Para acceder a la instancia usamos un consola virtual, capture la URL \e[m'
nova get-vnc-console demo-instance1 novnc
nova list

# Para acceder a la instancia de forma remota
echo -e '\n\e[33;1m Para acceder a la instancia de forma remota \e[m'
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0

# Permitir la conexiones ssh
echo -e '\n\e[33;1m Permitir la conexiones ssh \e[m'
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0

touch ./.launch-instance

echo "
##################################################################################################

La URL que capturo, puede colocarla en un navegador que tenga acceso a controller para que haga la 
conexion con la instancia.

En su Host puede editar '/etc/hosts' y agregar una linea como la siguiete con la IP que tiene controller
en la eth2, la que esta configurada en el adaptador de puente.

Luego desde el Host abre un navegador y coloca la URL que capturo.

tambien puede establecer conexion ssh con la instancia 
'nova list' ejecute esto en el nodo controller
obtenga la IP de la instancia
'ssh cirros@10.0.3.18' ejecute esto en el nodo compute1

Puede ahora continuar con '. ./openstack-horizon.sh'

##################################################################################################
"

