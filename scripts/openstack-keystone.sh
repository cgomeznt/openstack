#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ ! -f ./.rabbitmq ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

	 './openstack-rabbitmq.sh'

##################################################################################################
"
exit 1
fi

if [ ! -f ./password-table.sh ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

	'openstack-security.sh'

##################################################################################################
"
fi

source ./password-table.sh

cat >> ./password-table.sh << EOF
################################################################
# Prerequisitos para un token temporal, configuracion de keystone
################################################################
export OS_SERVICE_TOKEN=$(openssl rand -hex 10)
export OS_SERVICE_ENDPOINT=http://controller:35357/v2.0
EOF

cat >> ./admin-openrc.sh << EOF
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://controller:35357/v2.0
EOF

cat >> ./demo-openrc.sh << EOF
export OS_TENANT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://controller:5000/v2.0
EOF

# Instalamos los paquetes de keystone y de python-keystoneclient
apt-get install keystone python-keystoneclient -y

# Creamos un respaldo del archivo de configuracion original
if [ -f /etc/keystone/keystone.conf.out ] ; then
echo "El archivo ya existe, por lo que se reestablecera y luego sera adaptado por este script"
cp -dp /etc/keystone/keystone.conf.out /etc/keystone/keystone.conf
else
cp -dp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.out
fi

source ./password-table.sh

# Editamos el archivo /etc/keystone/keystone.conf para completar las siguientes acciones
sed -e "
/^#admin_token=.*$/s/^.*$/admin_token = $OS_SERVICE_TOKEN/
/^connection=.*$/s/^.*$/connection=mysql:\/\/keystone:$KEYSTONE_DBPASS@controller\/keystone/
/^#provider=.*$/s/^.*$/provider=keystone.token.providers.uuid.Provider/
/^#driver=keystone.token.*$/s/^.*$/driver=keystone.token.persistence.backends.sql.Token/
/^#driver=keystone.contrib.revoke.*$/s/^.*$/driver=keystone.contrib.revoke.backends.kvs.Revoke/
/^#verbose=.*$/s/^.*$/verbose=True/
" -i /etc/keystone/keystone.conf

# Poblar la base de datos de servicio de identidad 
su -s /bin/sh -c "keystone-manage db_sync" keystone

# Reiniciar el servicio
service keystone restart

sleep 6

# Como esta configuracion utiliza SQL eliminamos la base de datos en SQLite
rm -f /var/lib/keystone/keystone.db

# Recomendamos que utilice cron para configurar una tarea periódica que purga TOKEN caducado por hora
(crontab -l -u keystone 2>&1 | grep -q token_flush) || \
echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' \
>> /var/spool/cron/crontabs/keystone

source ./password-table.sh

# Crear ahora los tenants, users, and roles para que funcione kestone

# Tenants
echo "
#############################################
	Tenants
#############################################"
keystone tenant-create --name admin --description "Admin Tenant"
keystone tenant-create --name demo --description "Demo Tenant"
keystone tenant-create --name service --description "Service Tenant"

# Users
echo "
#############################################
	Users
#############################################"
keystone user-create --name admin --pass "$ADMIN_PASS" --email admin@gmail.com
keystone user-create --name demo --tenant demo --pass "$DEMO_PASS" --email demo@gmail.com

# Roles
echo "
#############################################
	Roles
#############################################"
keystone role-create --name admin

# Asigna Roles a los Users en los Tenants
echo "
#############################################
	Asigna Roles a los Users en los Tenants
#############################################"
keystone user-role-add --user admin --tenant admin --role admin

# Crear el service entity para el Identity service
echo "
#############################################
	Service para Identity service
#############################################"
keystone service-create --name keystone --type identity \
--description "OpenStack Identity"

sleep 2

# Crear el Identity service API endpoints
echo "
#############################################
	Endpoint para Identity service
#############################################"
keystone endpoint-create \
--service-id $(keystone service-list | awk '/ identity / {print $2}') \
--publicurl http://controller:5000/v2.0 \
--internalurl http://controller:5000/v2.0 \
--adminurl http://controller:35357/v2.0 \
--region regionOne

# Vaciamos las variables para continuar pero con la configuracion ya establecida desde o con keystone
unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT

sed -e "
/export OS_SERVICE_TOKEN=.*$/d
/export OS_SERVICE_ENDPOINT=.*$/d
" -i ./password-table.sh

touch ./.keystone

echo -e "
##############################################################################################

Realice las pruebas busque mas y vaya preparando el snmp

El ADMIN_PASS puede sacarlo de esta forma: 'grep -i admin_pass ./password-table.sh
'keystone --os-tenant-name admin --os-username admin --os-password ADMIN_PASS \
--os-auth-url http://controller:35357/v2.0 token-get'
'keystone --os-tenant-name admin --os-username admin --os-password ADMIN_PASS \
--os-auth-url http://controller:35357/v2.0 tenant-list'
'keystone --os-tenant-name admin --os-username admin --os-password ADMIN_PASS \
--os-auth-url http://controller:35357/v2.0 user-list'
'keystone --os-tenant-name admin --os-username admin --os-password ADMIN_PASS \
--os-auth-url http://controller:35357/v2.0 role-list'

Ahora hacemos las pruebas cargando las variables 'source ./admin-openrc.sh'
'keystone user-list && keystone tenant-list && keystone role-list && keystone service-list \
 && keystone endpoint-list'


Ahora puede continuar con 'openstack-network.sh'

##############################################################################################
"
