#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ ! -f ./.network-test ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-network-test.sh'

##################################################################################################
"
exit 1
fi

# Instalamos cpu-checker que nos ayuda a saber si nuestro equipo soporta virtualizacion
#apt-get install -y cpu-checker

# Hacemos el test
#/usr/sbin/kvm-ok

touch ./.server-test

clear 

if  [ "$(egrep -c '(vmx|svm)' /proc/cpuinfo)" != "0" ]; then
echo "
#################################################################################################

Su CPU soporta extensiones KVM. Si esta instalando OpenStack en una maquina virtual,
necesita agregar 'virt_type=qemu' el archivo nova.conf en /etc/nova/ y reiniciar todos los servicios
de nova services, esto tomelo en cuenta para cuando instale nova. lo antes dicho no es necesario
si esto es un equipo fisico.

Ahora ejecute '. ./openstack-ntp.sh'

##################################################################################################
"
else
echo "
##################################################################################################

Su CPU NO soporta extensiones KVM. deberia investigue antes de continuar

Usted puede modificar /etc/nova/nova-compute.conf (una vez instalado) para emular esta aceleracion:

[libvirt]
...
virt_type = qemu

Puede continuar con '. ./openstack-ntp.sh'

##################################################################################################
"
fi
