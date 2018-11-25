#!/bin/bash

# Vamos a crear los password requeridos
# openssl rand -hex 10
# vamos a guardar la tabla de password en el archivo passwd.out para luego optener de ahi las claves

source ../funciones/funciones-genericas
source ../mensajes/mensajes-genericos


# Verificar que se ejecute el script con root
VerificaIdRoot

# Verifica que sea el nodo controller ..!!
VerificaNodoController

# Verifica que se ejecutara primero openstack-inicio.sh
VerificaArchivoDeControl "./.inicio"

# Password para root de mysql o mariadb
rootmysql="export rootmysql"
rootmysql="$rootmysql=$(openssl rand -hex 10)"

# Password para el usuario guest de RabbitMQ
RABBIT_PASS="export RABBIT_PASS"
RABBIT_PASS="$RABBIT_PASS=$(openssl rand -hex 10)"

# Password para la BD de Identity service
KEYSTONE_DBPASS="export KEYSTONE_DBPASS"
KEYSTONE_DBPASS="$KEYSTONE_DBPASS=$(openssl rand -hex 10)"

# Password para user demo de Identity service
DEMO_PASS="export DEMO_PASS"
DEMO_PASS="$DEMO_PASS=$(openssl rand -hex 10)"

# Password para user admin de Identity service
ADMIN_PASS="export ADMIN_PASS"
ADMIN_PASS="$ADMIN_PASS=$(openssl rand -hex 10)"

# Password para la BD de Image service
GLANCE_DBPASS="export GLANCE_DBPASS"
GLANCE_DBPASS="$GLANCE_DBPASS=$(openssl rand -hex 10)"

# Password para user de Image service
GLANCE_PASS="export GLANCE_PASS"
GLANCE_PASS="$GLANCE_PASS=$(openssl rand -hex 10)"

# Password para la BD de Compute service
NOVA_DBPASS="export NOVA_DBPASS"
NOVA_DBPASS="$NOVA_DBPASS=$(openssl rand -hex 10)"

# Password para user de Compute service
NOVA_PASS="export NOVA_PASS"
NOVA_PASS="$NOVA_PASS=$(openssl rand -hex 10)"

# Password para la BD de Block Storage service
CINDER_DBPASS="export CINDER_DBPASS"
CINDER_DBPASS="$CINDER_DBPASS=$(openssl rand -hex 10)"

# Password para user de Block Storage service
CINDER_PASS="export CINDER_PASS"
CINDER_PASS="$CINDER_PASS=$(openssl rand -hex 10)"

# Password para la BD de Networking service
NEUTRON_DBPASS="export NEUTRON_DBPASS"
NEUTRON_DBPASS="$NEUTRON_DBPASS=$(openssl rand -hex 10)"

# Password para user de Networking service
NEUTRON_PASS="export NEUTRON_PASS"
NEUTRON_PASS="$NEUTRON_PASS=$(openssl rand -hex 10)"

# Password para la BD de Orchestration service
HEAT_DBPASS="export HEAT_DBPASS"
HEAT_DBPASS="$HEAT_DBPASS=$(openssl rand -hex 10)"

# Password para user de Orchestration service
HEAT_PASS="export HEAT_PASS"
HEAT_PASS="$HEAT_PASS=$(openssl rand -hex 10)"

# Password para la BD de Telemetry service
CEILOMETER_DBPASS="export CEILOMETER_DBPASS"
CEILOMETER_DBPASS="$CEILOMETER_DBPASS=$(openssl rand -hex 10)"

# Password para user de Telemetry service
CEILOMETER_PASS="export CEILOMETER_PASS"
CEILOMETER_PASS="$CEILOMETER_PASS=$(openssl rand -hex 10)"

# Password para la BD de Database service
TROVE_DBPASS="export TROVE_DBPASS"
TROVE_DBPASS="$TROVE_DBPASS=$(openssl rand -hex 10)"

# Password para user demo de Database service
TROVE_PASS="export TROVE_PASS"
TROVE_PASS="$TROVE_PASS=$(openssl rand -hex 10)"

cat > password-table.sh << EOF
#!/bin/bash
$rootmysql
$RABBIT_PASS
$KEYSTONE_DBPASS
$DEMO_PASS
$ADMIN_PASS
$GLANCE_DBPASS
$GLANCE_PASS
$NOVA_DBPASS
$NOVA_PASS
$CINDER_DBPASS
$CINDER_PASS
$NEUTRON_DBPASS
$NEUTRON_PASS
$HEAT_DBPASS
$HEAT_PASS
$CEILOMETER_DBPASS
$CEILOMETER_PASS
$TROVE_DBPASS
$TROVE_PASS
EOF

# Crea el archivo de control para saber que ya se ejecuto este script
touch ./.security

MuestraMensaje "$SECURITY_1"
