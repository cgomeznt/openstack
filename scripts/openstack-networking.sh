#!/bin/bash

source ../funciones/funciones-genericas
source ../mensajes/mensajes-genericos
source ../funciones/funciones-networking

# Verificar que se ejecute el script con root
VerificaIdRoot

# Verifica que sea el nodo controller ..!!
VerificaNodoController 

# Respaldo del hosts
RespaldoArchivo "/etc/hosts"

# Modificamos el hosts
ModificarHosts

# Respaldo de interface /etc/network/interfaces
RespaldoArchivo "/etc/network/interfaces"

# Le asignamos las IPs correspondiente al controller, network y a compute1
VerificaNodoController
if [ $? -eq 0 ]; then
	EditaInterfacesController
fi
VerificaNodoNetwork
if [ $? -eq 0  ]; then
	EditaInterfacesNetwork
fi
VerificaNodoCompute1
if [ $? -eq 0  ]; then
	EditaInterfacesCompute1
fi

# Reiniciamos los adaptadores de red
# ifdown --exclude=lo -a && sudo ifup --exclude=lo -a
ifdown eth0 && ifup eth0
ifdown eth1 && ifup eth1

# Crea el archivo de control para saber que ya se ejecuto este script
touch ./.networking

clear
MuestraMensaje "$NETWORKING_1"
