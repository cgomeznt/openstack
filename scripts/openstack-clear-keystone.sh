#!/bin/bash
clear
echo -e "
##############################################################################################

	Se procede a limpiar todos los registros de keystone

	Recuerda que esto va fallar si no tienes las variables para el token temporal
	OS_SERVICE_TOKEN
	OS_SERVICE_ENDPOINT

##############################################################################################"

sleep 3

export OS_SERVICE_TOKEN=$(grep admin_token /etc/keystone/keystone.conf | awk -F"=" '{print $2}')
export OS_SERVICE_ENDPOINT=http://controller:35357/v2.0

keystone user-list | awk ' / admin / {print $2}' |xargs  keystone user-delete
keystone user-list | awk ' / demo / {print $2}' |xargs  keystone user-delete
keystone tenant-list | awk ' / admin / {print $2}' |xargs  keystone tenant-delete
keystone tenant-list | awk ' / demo / {print $2}' |xargs  keystone tenant-delete
keystone tenant-list | awk ' / service / {print $2}' |xargs  keystone tenant-delete
keystone role-list | awk ' / admin / {print $2}' |xargs  keystone role-delete
keystone role-list | awk ' / _member_ / {print $2}' |xargs  keystone role-delete
keystone endpoint-list | awk ' / keystone / {print $2}' |xargs  keystone endpoint-delete

sed -e "
/^#.*$/d
/^# Prerequisitos.*$/d
/^export OS_SERVICE_TOKEN=$(openssl rand -hex 10).*$/d
/^export OS_SERVICE_ENDPOINT=http://controller:35357/v2..*$/d
" -i ./password-table.sh

rm ./.keystone ./admin-openrc.sh ./demo-openrc.sh
rm /etc/keystone/keystone.conf.out

# removemos los paquetes de keystone y de python-keystoneclient
apt-get remove --purge keystone python-keystoneclient -y
apt-get autoremove -y

unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT

source ./password-table.sh
echo -e "
##############################################################################################

	Coloque la clave del root de MariaDB o de MySQL

##############################################################################################
"
mysql -u root -p << EOF
DROP DATABASE keystone;
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY '$KEYSTONE_DBPASS';
EOF

echo -e "
##############################################################################################

	Se realizo la limpieza de keystone

	Ahora puede continuar nuevamente con 'openstack-keystone.sh'

##############################################################################################
"

