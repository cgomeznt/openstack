#!/bin/bash
# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ "14.04" == "$(lsb_release -a 2>/dev/null | awk '/Release/ {print $2}')" ]; then
clear
echo -e "
##############################################################################################

Excelente tiene Ubuntu

$(lsb_release -a 2>/dev/null)

##############################################################################################"

else
echo -e "
##############################################################################################

Debe tener ubunto 14.04 server, para poder ejecutar este laboratorio con exito.
Pero si usted quiere puede modificar el script y adaptarlo a su gusto...!!!

##############################################################################################"
exit 1
fi
echo -e " "
read -p "Presione cualquier tecla para continuar..." -n 1
clear
echo -e "
##############################################################################################

Debe tener claro que Arquitectura minima va utilizar, para eso vea el capitulo 1. Architecture de la guia de OpenStack
Figure 1.3. Minimal architecture example with OpenStack Networking(neutron)—Network layout
ó
Figure 1.6. Minimal architecture example with legacy networking (nova-network)—Network layout

Porque este script debe ejecutarlo en cada servidor en el que se monte el laboratorio.

##############################################################################################"
echo -e " "
read -p "Presione cualquier tecla para continuar..." -n 1
clear
echo -e "
##############################################################################################

Este script debe ejecutarlo en cada servidor. Porque modificara el nombre de los servidores,
las direcciones IPs y los DNS locales, para que quede tal cual como la guia de OpenStack.

##############################################################################################"
echo  " "

unset typeserver
until [ "$typeserver" == "1" ] || [ "$typeserver" == "2" ] || [ "$typeserver" == "3" ]
do 
read -p "Indique con el numero correspondiente, si este servidor es:
1.- El controller
2.- El network
3.- El compute1 " -n 1 typeserver
done

# Respaldo de /etc/hostname
if [ -f /etc/hostname.out ]; then
cp -dp /etc/hostname.out /etc/hostname
else
cp -dp /etc/hostname /etc/hostname.out
fi

case $typeserver in
	"1") echo "controller" > /etc/hostname
	;;
	"2") echo "network" > /etc/hostname
	;;
	"3") echo "compute1" > /etc/hostname
	;;
	*) exit 1
	;;
esac

touch ./.inicio
echo  " "
echo -e "
##############################################################################################

Se modifico el /etc/hostname y se creo un respaldo /etc/hostname.out, recuerde que debe ejecutar 
este script en los demas servidores

se cambio el nombre del equipo a $(cat /etc/hostname), debe reiniciar este equipo.

Despues de reiniciar ejecutamos '. ./openstack-security.sh'

##############################################################################################"

