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

if [ -f ./.packages ];then
echo "
##################################################################################################

Usted ya ejecuto este script debe continuar con 

'. ./openstack-database.sh' si esta en el controller 
o
'. ./openstack-nova-compute.sh' si esta en el compute1

##################################################################################################
"
exit 0
fi

clear
# Habilitamos el repositorio de OpenStack para la version que se quiera (icehouse, juno, kilo, liberty)
echo "
##################################################################################################

Debe seleccionar cual es la version de OpenStack que va instalar (icehouse, juno, kilo, liberty)

##################################################################################################"
echo  " "

unset SW
until [ $(echo $SW | grep [Ss]) ] 
do
unset verOpenStack
until [ $(echo $verOpenStack | grep [1234]) ]
do 
echo "" && read -p "Indique con el numero correspondiente, la version de OpenStack:
1.- icehouse
2.- juno
3.- kilo 
4.- liberty" -n 1 verOpenStack
done
case $verOpenStack in
	"1") echo "" && read -p "Usted selecciono icehouse, [S/n]:" -n 1 SW
		 echo -e '\n\e[33;1m Bien...!!! confirmo icehouse \e[m'
		 apt-get clean
		 # instalamos la llave
		 apt-get install python-software-properties
		 add-apt-repository cloud-archive:icehouse
		 # Actualizamo y hacemos un upgrade de Ubuntu
		 apt-get update && apt-get dist-upgrade -y
	;;
	"2") echo "" && read -p "Usted selecciono juno, [S/n]:" -n 1 SW
		 echo -e '\n\e[33;1m Bien...!!! confirmo juno \e[m'
		 apt-get clean
		 # instalamos la llave
		 apt-get install ubuntu-cloud-keyring
		 # agregamos el repositorio de juno
		 echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
		 "trusty-updates/juno main" > /etc/apt/sources.list.d/cloudarchive-juno.list
		 # Actualizamo y hacemos un upgrade de Ubuntu
		 apt-get update && apt-get dist-upgrade -y
	;;
	"3") echo "" && read -p "Usted selecciono kilo, [S/n]:" -n 1 SW
		 echo -e '\n\e[33;1m Bien...!!! confirmo kilo \e[m'
		 apt-get clean
		 # instalamos la llave
		 apt-get install ubuntu-cloud-keyring
		 # agregamos el repositorio de kilo
		 echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
		 "trusty-updates/kilo main" > /etc/apt/sources.list.d/cloudarchive-kilo.list
		 # Actualizamo y hacemos un upgrade de Ubuntu
		 apt-get update && apt-get dist-upgrade -y
	;;
	"4") echo "" && read -p "Usted selecciono liberty, [S/n]:" -n 1 SW
		 echo -e '\n\e[33;1m Bien...!!! confirmo liberty \e[m'
		 apt-get clean
		 # instalamos la llave
		 apt-get install software-properties-common
		 add-apt-repository cloud-archive:liberty
		 # Actualizamo y hacemos un upgrade de Ubuntu
		 apt-get update && apt-get dist-upgrade -y
	;;
	*) exit 1
	;;
esac
done
echo "" 

touch ./.packages

if [ "$(hostname)" == "controller" ]; then 
echo "
##################################################################################################

Debes reiniciar el equipo

Luego ejecute '. ./openstack-database.sh'

##################################################################################################
"
else
echo "
##################################################################################################

Debes reiniciar el equipo

Debe asegurar que desde el nodo controller se copie password-table.sh a el nodo compute1 
en la ruta que se encuentran todos los scripts

Luego ejecute '. ./openstack-nova-compute.sh'

##################################################################################################
"
fi
