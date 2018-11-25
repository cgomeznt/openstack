#!/bin/bash

# Verificar que se ejecute el script con root
if [ "$(id -u)" != "0" ]; then
	echo "Debe ser root para ejecutar los script." 1>&2
	exit 1
fi

if [ "$(hostname)" != "controller" ]; then
echo "
##################################################################################################

Este script solo se debe ejecutar en el nodo controller

##################################################################################################"
exit 1
fi

if [ ! -f ./.keystone ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-keystone.sh'

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
fi

if [ -f ./.glance ];then
echo "
##################################################################################################

Usted ya ejecuto este script debe continuar con 

'. ./openstack-nova-glance.sh' si solo si, esta en el controller

##################################################################################################
"
exit 0
fi

source ./password-table.sh
source ./admin-openrc.sh

# Crear las credenciales de servicio
echo -e '\n\e[33;1m Crear las credenciales de servicio \e[m'
keystone user-create --name glance --pass $GLANCE_PASS

# Agrega el role de admin para el usuario glance
echo -e '\n\e[33;1m Agrega el role de admin para el usuario glance \e[m'
keystone user-role-add --user glance --tenant service --role admin

# Crea el servicio glance del tipo image
echo -e '\n\e[33;1m Crea el servicio glance del tipo image \e[m'
keystone service-create --name glance --type image \
--description "OpenStack Image Service"

# Crea el Endpoint para el servicio glance
echo -e '\n\e[33;1m Crea el Endpoint para el servicio glance \e[m'
keystone endpoint-create \
--service-id $(keystone service-list | awk '/ image / {print $2}') \
--publicurl http://controller:9292 \
--internalurl http://controller:9292 \
--adminurl http://controller:9292 \
--region regionOne

# Instalamos los paquetes glance python-glanceclient
echo -e '\n\e[33;1m Instalamos los paquetes glance python-glanceclien \e[m'
apt-get install glance python-glanceclient -y

sleep 5


# Creamos un respaldo del archivo de configuracion original
echo -e '\n\e[33;1m Creamos un respaldo del archivo de configuracion original \e[m'
if [ -f /etc/glance/glance-api.conf.out ] ; then
echo "El archivo ya existe, por lo que se reestablecera y luego sera adaptado por este script"
cp -dp /etc/glance/glance-api.conf.out /etc/glance/glance-api.conf
else
cp -dp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.out
fi

# Editamos el archivo /etc/glance/glance-api.conf para completar las siguientes acciones
echo -e '\n\e[33;1m Editamos el archivo /etc/glance/glance-api.conf para completar las siguientes acciones \e[m'
sed -e "
/^#connection =.*$/s/^.*$/connection = mysql:\/\/glance:$GLANCE_DBPASS@controller\/glance/
/^identity_uri.*$/s/^.*$/auth_uri = http:\/\/controller:5000\/v2.0\nidentity_uri = http:\/\/controller:35357/
/^admin_tenant_name.*$/s/^.*$/admin_tenant_name = service/
/^admin_user.*$/s/^.*$/admin_user = glance/
/^admin_password.*$/s/^.*$/admin_password = $GLANCE_PASS/
/^#flavor.*$/s/^.*$/flavor = keystone/
/^filesystem_store_datadir.*$/s/^.*$/default_store = file \nfilesystem_store_datadir = \/var\/lib\/glance\/images\//
/^# notification_driver.*$/s/^.*$/notification_driver = noop/
/^#verbose.*$/s/^.*$/verbose = True/
" -i /etc/glance/glance-api.conf

# Creamos un respaldo del archivo de configuracion original
echo -e '\n\e[33;1m Creamos un respaldo del archivo de configuracion original \e[m'
if [ -f /etc/glance/glance-registry.conf.out ] ; then
echo "El archivo ya existe, por lo que se reestablecera y luego sera adaptado por este script"
cp -dp /etc/glance/glance-registry.conf.out /etc/glance/glance-registry.conf
else
cp -dp /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.out
fi

# Editamos el archivo /etc/glance/glance-registry.conf para completar las siguientes acciones
echo -e '\n\e[33;1m Editamos el archivo /etc/glance/glance-api.conf para completar las siguientes acciones \e[m'
sed -e "
/^#connection.*$/s/^.*$/connection = mysql:\/\/glance:$GLANCE_DBPASS@controller\/glance/
/^identity_uri.*$/s/^.*$/auth_uri = http:\/\/controller:5000\/v2.0\nidentity_uri = http:\/\/controller:35357/
/^admin_tenant_name.*$/s/^.*$/admin_tenant_name = service/
/^admin_user.*$/s/^.*$/admin_user = glance/
/^admin_password.*$/s/^.*$/admin_password = $GLANCE_PASS/
/^#flavor.*$/s/^.*$/flavor = keystone/
/^# notification_driver.*$/s/^.*$/notification_driver = noop/
/^#verbose.*$/s/^.*$/verbose = True/
" -i /etc/glance/glance-registry.conf

# Poblamos la base de datos de glance
echo -e '\n\e[33;1m Poblamos la base de datos de glance \e[m'
su -s /bin/sh -c "glance-manage db_sync" glance

# Reiniciamos los servicios
echo -e '\n\e[33;1m Reiniciamos los servicios \e[m'
service glance-registry restart
sleep 6
service glance-api restart
sleep 6

# Como esta configurado SQL por defecto, borramos la base de datos de SQLite
echo -e '\n\e[33;1m Como esta configurado SQL por defecto, borramos la base de datos de SQLite \e[m'
rm -f /var/lib/glance/glance.sqlite

echo '\n\e[33;1m 
##################################################################################################

La instalacion y configuracion ya culmino, ahora vamos a verificar.
Primero vamos a descargar de cirros y de ubuntu unas imagenes para cargarla en glance

################################################################################################## \e[m'

# Descargamos las imagenes
mkdir /tmp/images
echo -e '\n\e[33;1m Descargando imagen cirros-0.3.3-x86_64-disk.img \e[m'
wget -P /tmp/images http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img
unset SW
read -p "Le gustaria descargar la imagen (precise-server-cloudimg-amd64-disk1.img) de 251M [S/n]: " -n 1 SW
if [ $(echo $SW | grep [Ss]) ]; then
echo -e '\n\e[33;1m Descargando imagen precise-server-cloudimg-amd64 \e[m'
wget -P /tmp/images http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img
fi

source admin-openrc.sh

# Cargamos dentro de glance las imagenes descargadas
echo -e '\n\e[33;1m Creando la imagen de cirros-0.3.3-x86_64 \e[m'
glance image-create --name "cirros-0.3.3-x86_64" --file /tmp/images/cirros-0.3.3-x86_64-disk.img \
--disk-format qcow2 --container-format bare --is-public True --progress

if [ $(echo $SW | grep [Ss]) ]; then
echo -e '\n\e[33;1m Creando la imagen de precise-server-cloudimg-amd64 \e[m'
glance image-create --name "precise-server-cloudimg-amd64" --file /tmp/images/precise-server-cloudimg-amd64-disk1.img \
--disk-format qcow2 --container-format bare --is-public True --progress
fi

# glance image-create --name="Ubuntu Precise 12.04 LTS" --location=http://cloud-images.ubuntu.com/precise/current/precise-server-cloudimg-amd64-disk1.img \
#--disk-format=qcow2 --container-format=bare --is-public=True  --progress

# Listamos las imagenes disponibles
echo -e '\n\e[33;1m ejecutamos  glance image-list \e[m'
glance image-list

touch ./.glance

echo -e "
##############################################################################################

Realice las pruebas, busque mas y vaya preparando el snmp
'glance image-list'


Ahora puede continuar con '. ./openstack-nova-controller.sh'

##############################################################################################
"
