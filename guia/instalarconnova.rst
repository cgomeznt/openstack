instalar OpenStack con la arquitectura de nodos (nova-network)
==============================================================


Vamos a colocar las siguientes imagenes que son importante tenerlas presente. Si las entiendes significa que todo se le hara muy facil, si no las entiende es mejor que se detenga y las analice bien.

Arquitectura minima de ejemplo con legacy networking (nova-network)— Hardware requirements
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.. figure:: ../images/nova/Minimal_architecture_nova-network.png

Arquitectura minima de ejemplo con legacy networking (nova-network)— Capa de Red
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.. figure:: ../images/nova/Minimal_architecture_nova-network_1.png

Arquitectura minima de ejemplo con legacy networking (nova-network)— Capa de Servicio
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.. figure:: ../images/nova/Minimal_architecture_nova-network_2.png


Ya teniendo claro esta infraestructura vamos a encender las dos maquinas virtuales y nos conectarnos a ellas con ssh, recuerde descargar el proyecto::

	$ git clone https://github.com/cgomeznt/openstack.git

para que copie los script en los servidores, tambien puede ir abriendo cada script copiar el contenido y luego crear el script en los servidores. (utilice la tecnica que usted prefiera) 


Iniciamos las dos (2) maquinas virtuales creadas con virtualbox. Recuerden que solo le instalamos el Ubuntu con openssh-server, git y ni las tarjetas de redes estan configuradas.

Iniciamos en cada una de ellas y vemos cual es la dirección ip que obtuvieron en el eth2 la cual esta configurada en el **adaptador de puente**, esto lo hacemos para poder conectarnos por medio de ssh desde el Host hacia ellas. Recuerde que en este adaptador usted tiene conexion hacia el internet (Tomando en cuenta que usted ya tiene conexion a internet con su Host).

Por lo normal siempre la gente tiene problemas con la configuracion del route y de los DNS, por eso vamos a realizar primero unas pruebas en los servidores. Imaginemos que en el eth2 que esta por el **adaptador de puente** entrega IP del segmento 192.168.1.0/24 y que el default gateway debe ser 192.168.1.1 y los DNS deberia ser 192.168.1.1 si este cumple este papel, sino podemos colocar los DNS de google 8.8.8.8, `vamos a verificar <verificargwdns.rst>`_

Copiar el proyecto en cada una de ellas con la tecnica que usted prefiera, puede hacerlo con git en cada una de ellas::

	$ git clone https://github.com/cgomeznt/openstack.git


De ahora en adelante, vamos a llamar a los servidores nodo controller y nodo compute1. tambien se dara cuenta que los scripts le estara dando recomendaciones.

Comencemos con el que sera nodo controller

nodo controller
++++++++++++++++++
::

# sudo su

::

# cd openstack/scripts/

::

# . openstack-inicio.sh

Debe reiniciar el equipo y siempre recuerde hacer ``sudo su`` y cd openstack/scripts/
::

# . openstack-security.sh

::

# . openstack-networking.sh 

Edite el archivo /etc/network/interfaces y configure la eth0 para que quede como en la guía de OpenStack::

	# vi /etc/network/interfaces
		auto eth0
		iface eth0 inet static
		address 10.0.0.11
		netmask 255.255.255.0

::

	# ifdown eth0 && ifup eth0 && ifconfig eth0
		eth0  Link encap:Ethernet  HWaddr 08:00:27:8b:e8:0b  
		      inet addr:10.0.0.11  Bcast:10.0.0.255  Mask:255.255.255.0
		      inet6 addr: fe80:a00:27ff:fe8b:e80b/64 Scope:Link
		      UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
		      RX packets:35 errors:0 dropped:0 overruns:0 frame:0
		      TX packets:61 errors:0 dropped:0 overruns:0 carrier:0
		      collisions:0 txqueuelen:1000 
		      RX bytes:11970 (11.9 KB)  TX bytes:18522 (18.5 KB)

Luego que configure la ip 10.0.0.11 en le eth0 continue con::

# . openstack-network-test.sh 

Es logico que el nodo compute1 no responda porque aun no lo hemos configurado y el nodo network porque no lo utilizaremos, pero controller y openstack.org si deben responder. `si falla verificar gateway o DNS <verificargwdns.rst>`_
::

# openstack-server-test.sh

::

# . openstack-ntp.sh

::

# . openstack-packages.sh

Debes reiniciar el equipo y siempre recuerde hacer ``sudo su`` y cd openstack/scripts/luego de reiniciar siempre, tambien debe verificar la conectividad de red y el NTP
::

# . openstack-database.sh


Mucho cuidado con la clave que le va pedir, deber recordarla porque esa clave es del manejador de base de datos MariaDB. Luego el te pedira que coloques el passwor de root (recuerda es del manejador de base de datos MariaDB) cuando te pregunte si quieres cambiar el password le dice que NO y al resto de las opciones le dice que Yes. Cuando te pregunte nuevamente por la clave de root se la suministras. No deje de hacer las pruebas que te indica el script
::

# . openstack-rabbitmq.sh

Realice las pruebas que le indica el script. Se crearon dos archivos en python (send.py y recived.py) que son muy utiles para resolver fallas con rabbitMQ-server, para darle una idea puede ejecutar recived.py en el controller para que se quede escuchando todas las peticiones y desde su equipo Host puede ejecutar send.py (claro en send.py debe editarlo y donde dice controller colocar la IP del controller y en "credentials = pika.PlainCredentials('guest', 'AQUI VA LA CLAVE')", recuerde que las claves esta en "cat password-table.sh". Si llegarar a fallar reinicie el servicio de rabbitMQ-server
::

# /etc/init.d/rabbitmq-server restart

::

# . openstack-keystone.sh

::

# . openstack-glance.sh

::

# . openstack-nova-controller.sh

::

# . openstack-nova-network.sh

Debemos copiarnos el archivo que contiene los password al nodo compute1
::

# scp password-table.sh usuario@compute1:/tmp

Ahora debemos pasar al nodo compute1.


nodo compute1
++++++++++++++++++
::

# sudo su


::

# cd openstack/scripts/

::

# openstack-inicio.sh

Debe reiniciar el equipo y siempre recuerde hacer ``sudo su`` y cd openstack/scripts/
::

# openstack-networking.sh

Edite el archivo /etc/network/interfaces y configure la eth0 y la eth1 para que quede como en la guía de OpenStack, pero antes capturen con ifconfig eth1 que IP tiene porque luego la utilizaremos::

	# vi /etc/network/interfaces
		auto eth0
		iface eth0 inet static
		address 10.0.0.31
		netmask 255.255.255.0

		auto eth1
		iface eth1 inet manual
		  up ip link set dev $IFACE up
		  down ip link set dev $IFACE down

::

	# ifdown eth0 && ifup eth0 && ifconfig eth0
		eth0  Link encap:Ethernet  HWaddr 08:00:27:8b:e9:1b  
		      inet addr:10.0.0.31  Bcast:10.0.0.255  Mask:255.255.255.0
		      inet6 addr: fe80:a00:28ff:fe8b:e90b/64 Scope:Link
		      UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
		      RX packets:35 errors:0 dropped:0 overruns:0 frame:0
		      TX packets:61 errors:0 dropped:0 overruns:0 carrier:0
		      collisions:0 txqueuelen:1000 
		      RX bytes:11970 (11.9 KB)  TX bytes:18522 (18.5 KB)

Lo siguiente deberia funcionar pero aun no descubro porque falla, por lo tanto y muy mala practica reinicio el nodo compute1
::

	# ifdown eth1 && ifup eth1 && ifconfig eth1

Luego que configure la ip 10.0.0.31 en le eth0 y la eth1 la colocamos en manual, continue con::

# openstack-network-test.sh

El nodo network no responde porque no lo utilizaremos, pero controller, compute1 y openstack.org si deben responder. `si falla verificar gateway o DNS <verificargwdns.rst>`_
::

# openstack-server-test.sh

::

# openstack-ntp.sh

::

# openstack-packages.sh

Debes reiniciar el equipo y siempre recuerde hacer ``sudo su`` y cd openstack/scripts/luego de reiniciar siempre, tambien debe verificar la conectividad de red y el NTP
::

Recuerdan el archivo password-table.sh que copiamos del nodo controller a compute1, pues ahora debemos colocarlo en la ruta en doden se encuentran todos los scripts
::

# mv /tmp/password-table.sh .

Ahora si podemos instalar los paquetes de nova-compute
::

# openstack-nova-compute.sh

Vamos un momento al nodo controller para verificar que todo marche bien y que ya este viendo al nodo compute1, les recuerdo, cuidado con las claves que se utilizaron en /etc/nova/nova.conf siempre hay errores con eso y pendiente con rabbitMQ-server
::

 # /etc/init.d/rabbitmq-server restart
 # . openstack-nova-restart-service.sh
 # source admin-openrc.sh && nova service-list

::

Regresamos al nodo compute1 para ejecutar
::

# openstack-nova-network.sh

Listo, vamos al nodo controller a  crear una infraestructura de red virtual, recuerden que en la interface eth1 la configuramos como manual y que se les habia dicho que guardaran la IP que le estaba entregando el DHCP del NAT, imaginen que dio 10.0.3.15 (la adaptan a lo que ustedes le dio)
::

 # source admin-openrc.sh
 # nova network-create demo-net --bridge br100 --multi-host T --fixed-range-v4 10.0.3.20/29
 # nova net-list





Continuamos trabajando...!!!
