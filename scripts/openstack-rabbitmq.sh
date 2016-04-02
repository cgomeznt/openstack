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

if [ ! -f ./.database ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'./openstack-database.sh'

##################################################################################################
"
exit 1
fi

if [ ! -f ./password-table.sh ];then
echo "
##################################################################################################

No puede hacer este paso debe ejecutar primero

'. ./openstack-security.sh'

##################################################################################################
"
exit 1
fi

if [ -f ./.rabbitmq ];then
echo "
##################################################################################################

Usted ya ejecuto este script debe continuar con 

'. ./openstack-keystone.sh' si solo si, esta en el controller

##################################################################################################
"
exit 0
fi

# Instalamos RabbitMQ
apt-get install rabbitmq-server -y

source ./password-table.sh

# Cambiamos la clave del usuario guest por la que tenemos en nuestra tabla de claves 'password-table.sh'
rabbitmqctl change_password guest $RABBIT_PASS

# Creamos el archivo pero debemos estar pendinte porque dependiendo de la version este archivo existe
if [ ! -f /etc/rabbitmq/rabbitmq.config ];then
cat > /etc/rabbitmq/rabbitmq.config << EOF
[{rabbit, [{loopback_users, []}]}].
EOF
fi

service rabbitmq-server restart

sleep 6

rabbitmqctl status | grep rabbit

# Instalamos Pika para probar rabbitmq-server
# http://www.rabbitmq.com/tutorials/tutorial-one-python.html
apt-get install python-pika -y

cat > ./send.py << EOF
#!/usr/bin/env python
import pika

credentials = pika.PlainCredentials('guest', '$RABBIT_PASS')
connection = pika.BlockingConnection(pika.ConnectionParameters(
               'localhost', 5672, '/', credentials))
channel = connection.channel()



channel.queue_declare(queue='hello')

channel.basic_publish(exchange='', routing_key='hello', body='Este es el cuerpo...!!!')
print(" [x] Se envio un mensaje...!! ")
connection.close()
EOF

cat > ./recived.py << EOF
#!/usr/bin/env python
import pika

credentials = pika.PlainCredentials('guest', '$RABBIT_PASS')
connection = pika.BlockingConnection(pika.ConnectionParameters(
               'localhost', 5672, '/', credentials))
channel = connection.channel()


channel.queue_declare(queue='hello')

def callback(ch, method, properties, body):
    print(" [x] Recibiendo %r" % body)

channel.basic_consume(callback,
                      queue='hello',
                      no_ack=True)

print(' [*] . Tpere por mas mensajes, para salir presione  CTRL+C')
channel.start_consuming()
EOF

touch ./.rabbitmq

echo -e "
##############################################################################################

Realice estas pruebas

'rabbitmqctl status | grep rabbit' 'lsof -i :5672' 

'telnet localhost 5672
Connected to localhost.
Escape character is '^]'.
adjasd
AMQP    Connection closed by foreign host.'

'python send.py'
 [x] Se envio un mensaje...!! 
No handlers could be found for logger pika.adapters.base_connection

'rabbitmqctl list_queues'
Listing queues ...
hello	1
...done.

'python recived.py'  <== Despues de levantar corre varias veces el python send.py desde otra consola
 [x] Recibiendo 'Este es el cuerpo...!!!'
 [*] . Tpere por mas mensajes, para salir presione  CTRL+C

Busca mas alternativas para realizar pruebas y vaya preparando el snmp

Ahora puede continuar con '. ./openstack-keystone.sh'

##############################################################################################"


