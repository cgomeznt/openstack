#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ ! -f ./.packages ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

	'./openstack-packages.sh'

##################################################################################################
"
exit 1
fi

if [ ! -f ./password-table.sh ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

Ejecute 'openstack-security.sh'

##################################################################################################
"
exit 1
fi

# Instalamos MariaDB
clear
echo "
##############################################################################################

Configurando MariaDB / MySQL .  Se le preguntara el password de root password para continuar
no olvide el password

##############################################################################################"
sleep 5
apt-get install mariadb-server python-mysqldb -y

# Se configura para que escuche las peticiones por la IP administrativa
sed -i '/^bind-address/s/127.0.0.1/10.0.0.11/g' /etc/mysql/my.cnf

# Configuramos el soporte utf8 and innodb
echo "
[mysqld]
default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8
" >> /etc/mysql/conf.d/openstack.cnf

# restart
service mysql restart

sleep 6

echo "
##############################################################################################

Ahora vamos a ejecutar el mysql_secure_installation para aumentar los niveles de seguridad

##############################################################################################"
# secure mysql
mysql_secure_installation

# Se crearan cada una de las base de datos para los servicios.
source ./password-table.sh

echo "
##############################################################################################

Se le va pedir la clave de root que usted coloco para el manejador de Base de Datos

##############################################################################################"

mysql -u root -p << EOF
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY '$KEYSTONE_DBPASS';
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
IDENTIFIED BY '$GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
IDENTIFIED BY '$GLANCE_DBPASS';
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' \
IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' \
IDENTIFIED BY '$NOVA_DBPASS';
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' \
IDENTIFIED BY '$CINDER_DBPASS';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' \
IDENTIFIED BY '$CINDER_DBPASS';
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
IDENTIFIED BY '$NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
IDENTIFIED BY '$NEUTRON_DBPASS';
CREATE DATABASE heat;
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' \
IDENTIFIED BY '$HEAT_DBPASS';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' \
IDENTIFIED BY '$HEAT_DBPASS';
CREATE DATABASE ceilometer;
GRANT ALL PRIVILEGES ON ceilometer.* TO 'ceilometer'@'localhost' \
IDENTIFIED BY '$CEILOMETER_DBPASS';
GRANT ALL PRIVILEGES ON ceilometer.* TO 'ceilometer'@'%' \
IDENTIFIED BY '$CEILOMETER_DBPASS';
CREATE DATABASE trove;
GRANT ALL PRIVILEGES ON trove.* TO 'trove'@'localhost' \
IDENTIFIED BY '$TROVE_DBPASS';
GRANT ALL PRIVILEGES ON trove.* TO 'trove'@'%' \
IDENTIFIED BY '$TROVE_DBPASS';
EOF

touch ./.database
echo "
##############################################################################################

Puede verificar 'mysql -u root -p' y luego 'show databases;' o puede validarce con cada usuario
'mysql -u keystone -p' 'show databases;' 'use keystone' 'show tables'
'mysql -u nova -p' 'show databases;' 'use nova' 'show tables'
'mysql -u glance -p' 'show databases;' 'use glance' 'show tables'

Ahora puede continuar con 'openstack-rabbitmq.sh'

##############################################################################################"
