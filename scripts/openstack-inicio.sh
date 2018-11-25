#!/bin/bash

source ../funciones/funciones-genericas
source ../mensajes/mensajes-genericos
source ../funciones/funciones-inicio
source ../mensajes/mensajes-inicio

# Verificar que se ejecute el script con root
VerificaIdRoot

# Valida que tenga Ubuntu 14.04.4
ValidarVerUbuntu

# Pide presionar cualquier tecla
PressAnyKey

# Muestra un mensaje
MuestraMensaje "$INICIO_1"

# Pide presionar cualquier tecla
PressAnyKey

# Muestra un mensaje
MuestraMensaje "$INICIO_2"

# Respaldo de /etc/hostname
RespaldoArchivo "/etc/hostname"

#Pregunta si el servidor es el controller, network o compute1
ValidarTipoServidor

# Crea el archivo de control para saber que ya se ejecuto este script
touch ./.inicio

# Muestra un mensaje
MuestraMensaje "$INICIO_3"

