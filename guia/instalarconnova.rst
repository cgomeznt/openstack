instalar OpenStack con la arquitectura de nodos (nova-network)
==============================================================


Vamos a colocar las siguientes imágenes que son importante tenerlas presente. Si las entiendes significa que todo se le hará muy fácil, si no las entiende es mejor que se detenga y las analice bien.

Arquitectura mínima de ejemplo con legacy networking (nova-network)— Requerimientos Hardware
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.. figure:: ../images/nova/Minimal_architecture_nova-network.png

Arquitectura mínima de ejemplo con legacy networking (nova-network)— Capa de Red
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.. figure:: ../images/nova/Minimal_architecture_nova-network_1.png

Arquitectura mínima de ejemplo con legacy networking (nova-network)— Capa de Servicio
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.. figure:: ../images/nova/Minimal_architecture_nova-network_2.png


Ya teniendo claro esta infraestructura vamos a encender las dos maquinas virtuales y nos conectamos a ellas. (Deben tener los tres adaptadores de red como se indico, sino `vea esto <maquinasvirtuales.rst>`_

De ahora en adelante, vamos a llamar a los servidores **nodo controller** y **nodo compute1**.

vamos a conectarnos al que sera el **nodo controller** para configurar la IPs, por comodidad siempre vamos hacer primero ``sudo su``::

# sudo su

Editamos el /etc/network/interface para editar el adaptador eth2, para que quede como se muestra a continuación::

 # vi /etc/network/interface
 auto eth2
 iface eth2 inet dhcp

Iniciamos el adaptador eth2::

 # ifdown eth2 && ifup eth2 && ifconfig eth2

Volvemos a editar /etc/network/interface para colocar en el eth2 de forma estatica con la IP que capturo, esto lo hacemos para tener una administracion más facil a lo largo del laboratorio y para hacer las pruebas de forma más rapida::

# vi /etc/network/interface
 auto eth2
 iface eth2 inet static
 address 192.168.1.31
 netmask 255.255.255.0
 gateway 192.168.1.1
 dns-nameserver 192.168.1.1

Reiniciamos nuevamente el adaptador eth2::

 # ifdown eth2 && ifup eth2 && ifconfig eth2

Probamos el ICMP, debe responder::

# ping -c 4 openstack.org

Vamos hacer lo mismo con el que sera nodo **nodo compute1**::

# sudo su

Editamos el /etc/network/interface para editar el adaptador eth2, para que quede como se muestra a continuación::

 # vi /etc/network/interface
 auto eth2
 iface eth2 inet dhcp

Iniciamos el adaptador eth2::

 # ifdown eth2 && ifup eth2 && ifconfig eth2

Volvemos a editar /etc/network/interface para colocar en el eth2 de forma estatica con la IP que capturo::

# vi /etc/network/interface
 auto eth2
 iface eth2 inet static
 address 192.168.1.31
 netmask 255.255.255.0
 gateway 192.168.1.1
 dns-nameserver 192.168.1.1

Reiniciamos nuevamente el adaptador eth2::

 # ifdown eth2 && ifup eth2 && ifconfig eth2

Probamos el ICMP, debe responder::

# ping -c 4 openstack.org

Ahora en nuestro Host, vamos editar el /etc/hosts y agregamos estas dos lineas::

 # vi /etc/hosts
 192.168.1.11	controller
 192.168.1.31	compute1

Realizamos una prueba de conectividad desde el Host hacia **nodo controller** y **nodo compute1** ::

# for i in controller compute1; do ping -c 4 $i; done

Vamos instalar dos paquetes en **nodo controller** y **nodo compute1** que son openssh-server y git::

# apt-get update && apt-get install openssh-server git -y

Ya desde nuestro Host podemos conectarnos al **nodo controller** y al **nodo compute1** con un mismo terminal en pestañas distintas (en el ssh utilizo **usuario** porque ese fue el nombre que se le dio al usuario en la instalación de ubuntu)::

# ssh usuario@controller

::

# ssh usuario@compute1

Importante recordar que todo los comando que ejecutemos seran dentro del perfil del usuario, ejemplo /home/usuario  y todos los scripts en /home/usuario/openstack/scripts

En ambos equipos, **nodo controller** y **nodo compute1** ejecutamos::

$ git clone https://github.com/cgomeznt/openstack.git

Por lo normal siempre la gente tiene problemas con la configuración del route y de los DNS, por eso vamos a realizar primero unas pruebas en los servidores. Imaginemos que en el eth2 que esta por el `adaptador de puente <maquinasvirtuales.rst>`_ entrega IP del segmento 192.168.1.0/24 y que el default gateway debe ser 192.168.1.1 y el DNS deberia ser 192.168.1.1 si el route puede cumplir este papel, sino podemos colocar los DNS de google 8.8.8.8, `vamos a verificar <verificargwdns.rst>`_

Comencemos con el que sera **nodo controller** 

nodo controller
++++++++++++++++++
::

# sudo su

Todos los scripts deben ser siempre ejecutados en esta ruta::

# cd openstack/scripts/

Ejecute el siguiente script y seleccione (1) para el **nodo controller**::

# . openstack-inicio.sh

Debe reiniciar el equipo y luego de iniciar, recuerde hacer ``sudo su`` y cd openstack/scripts/
::

# . openstack-security.sh

::

# . openstack-networking.sh 

Continué con::

# . openstack-network-test.sh 

Es lógico que el nodo compute1 no responda porque aun no lo hemos configurado y el nodo network porque no lo utilizaremos, pero controller y openstack.org si deben responder. `si falla verificar gateway o DNS <verificargwdns.rst>`_

El siguiente script le indicara que su CPU NO soporta extensiones KVM, es porque estan virtualizados con virtualbox, omita ese mensaje. Continué::

# . openstack-server-test.sh

En el **nodo controller** se configura los NTP atomicos de Ubuntu y en **nodo compute1** se configura al **nodo controller** como su NTP. Continué con::

# . openstack-ntp.sh

Ahora vamos a seleccionar la versión de OpenStack que vamos a utilizar, en este caso seleccione (3) para la versión de kilo, se va conectar a los repositorios de Ubuntu para hacer la actualizacion de la distro. Continué con::

# . openstack-packages.sh

Debe reiniciar el equipo y luego de iniciar, recuerde hacer ``sudo su`` y cd openstack/scripts/ debe también verificar la conexión de red y el NTP

Ahora se va instalar el manejador de base de datos MariaDB, debe tener mucho cuidado con la clave que coloque, debe recordarla porque esa clave es del manejador de base de datos de MariaDB. Luego le pedirá que coloques el password de root (recuerda es del manejador de base de datos de MariaDB), cuando le pregunte si quieres cambiar el password usted debe indicar que NO y al resto de las opciones le dice que Yes. Cuando le pregunte nuevamente por la clave de root (recuerda es del manejador de base de datos de MariaDB) se la suministras. No deje de hacer las pruebas que te indica el script
::

# . openstack-database.sh

Continué con::

# . openstack-rabbitmq.sh

Realice las pruebas que le indica el script. Se crearon dos archivos en python (send.py y recived.py) que son muy útiles para resolver fallas con rabbitMQ-server, para darle una idea puede ejecutar recived.py en el controller para que se quede escuchando todas las peticiones y desde su equipo Host puede ejecutar send.py (claro en send.py debe editarlo y donde dice controller colocar la IP del controller y en "credentials = pika.PlainCredentials('guest', 'AQUI VA LA CLAVE')", recuerde que las claves esta en "cat password-table.sh". Si llegara a fallar reinicie el servicio de rabbitMQ-server. Continué con::

# . openstack-keystone.sh

De ahora en adelante cada vez que reinicie el **nodo controller** y requiera ejecutar comandos de OpenStack debe ir a openstack/scripts y luego ejecutar ``source ./admin-openrc.sh`` no lo olvide...!!!

Instalaremos glance que es donde se almacenan las imagens, cuando culmine el script podra ejecutar ``glance image-list`` Continué con::

# . openstack-glance.sh

Instalamos nova. Continué con::

# . openstack-nova-controller.sh

Configuramos nova-network. Continué con::

# . openstack-nova-network.sh

Ahora debemos pasar al nodo compute1.


nodo compute1
++++++++++++++++++
::

# sudo su

Todos los scripts deben ser siempre ejecutados en esta ruta::

# cd openstack/scripts/

Ejecute el siguiente script y seleccione (3) para el **nodo compute1**::

# . openstack-inicio.sh

Debe reiniciar el equipo y luego de iniciar, recuerde hacer ``sudo su`` y cd openstack/scripts/::

# . openstack-networking.sh 

Continué con::

# . openstack-network-test.sh 

El nodo network no responde porque no lo utilizaremos, pero controller, compute1 y openstack.org si deben responder. `si falla verificar gateway o DNS <verificargwdns.rst>`_ este scipt pudiera ejecutarlo nuevamente en el **nodo controller** porque tiene que dar este mismo resultado

El siguiente script le indicara que su CPU NO soporta extensiones KVM, es porque estan virtualizados con virtualbox, omita ese mensaje. Continué con::

# openstack-server-test.sh

En el **nodo controller** se configura los NTP atomicos de Ubuntu y en el **nodo compute1** se configura al **nodo controller** como su NTP. Continué con::

# . openstack-ntp.sh

Ahora vamos a seleccionar la versión de OpenStack que vamos a utilizar, en este caso seleccione (3) para la versión de kilo, se va conectar a los repositorios de Ubuntu para hacer la actualizacion de la distro. Continué con::

# . openstack-packages.sh

Debemos copiarnos el archivo password-table.sh que esta en el ***nodo controller** (contiene los password) al **nodo compute1**, no conectamos al ***nodo controller** (antes no lo habiamos hecho porque en el **nodo compute1** no estaba configurada los adaptadores de red). Ejecute::

# scp password-table.sh usuario@compute1:/tmp

A continuacion nos conectamos nuevamente al **nodo compute1**, el archivo copiado en password-table.sh en "/tmp" lo movemos a la ruta donde se encuentran todos los scripts "/openstack/scripts". Continué con::

# mv /tmp/password-table.sh .

Debe reiniciar el equipo y luego de iniciar, recuerde hacer ``sudo su`` y cd openstack/scripts/ debe también verificar la conexión de red y el NTP

Ahora si podemos instalar los paquetes de nova en **nodo compute1**::

# . openstack-nova-compute.sh

Vamos un momento al **nodo controller** para verificar que todo marche bien y que ya este viendo al **nodo compute1**, les recuerdo, cuidado con las claves que se utilizaron en /etc/nova/nova.conf siempre hay errores con eso y pendiente con rabbitMQ-server::

 # source admin-openrc.sh && nova service-list

Regresamos al **nodo compute1** para ejecutar::

# . openstack-nova-network.sh

Listo ya terminamos por los momentos en el **nodo compute1**

nodo controller
++++++++++++++++++

Vamos al **nodo controller** para crear una infraestructura de red virtual::

 # source admin-openrc.sh
 # nova network-create demo-net --bridge br100 --multi-host T --fixed-range-v4 10.0.3.20/29
 # nova net-list

Hasta aqui vamos bien y ya podemos crear una instancia dentro de nuestro OpenStack, para emocionarnos un poco y ver que si funciona.

Ejecute el siguiente comando en el **nodo controller**, pulse Enter cuando le pregunte "Enter file in which to save the key (/root/.ssh/id_rsa):", nuevamente Enter cuando le pregunte "Enter passphrase (empty for no passphrase):" y con "Enter same passphrase again:" un ultmo Enter.::

# . openstack-launch-instance.sh

Cuando culmine no deje de hacer lo que le indica el script. La URL que capturo o que puede capturar con el siguiente comando::

# nova get-vnc-console demo-instance1 novnc

Luego desde el Host abra un navegador y coloca la URL que capturo, deberá ver algo como la siguiente imagen

.. figure:: ../images/urlinstancia.jpg

Cuando inicie sesión en la instancia ( el usuario es **cirros** y la clave **cubswin:)** ) ejecute un ping a openstack.org y vera que resuelve el DNS pero no responde el ICMP, el siguiente comando que vamos a ejecutar no esta bien, pero lo hacemos solo para enrutar el trafico de las IPs asignadas a las instancias por la eth2 que si tiene salida al Internet, ejecute el siguiente comando en el **nodo compute1**
::

# iptables -t nat -A POSTROUTING -o eth2 -j MASQUERADE

Ahora vamos nuevamente a la instancia, detenemos el ping y lo volvemos a iniciar el ping a openstack.org, ahora si hay respuesta.

También puede establecer conexión ssh con la instancia, para eso ejecutamos este comando para obtener la IP de la instancia, pero desde el **nodo controller**::

# nova list

Luego nos vamos al **nodo compute1** y ejecutamos (con la IP que usted capturo)
::

# ssh cirros@10.0.3.18

Ahora instalemos el dashboard nombre codigo Horizon, esto sera más grafico y ya los administradores se sentirán más cómodos, en el **nodo controller** ::

# . openstack-horizon.sh

En nuestro Host accedemos al dashboard usando un navegado web http://controller/horizon , vera algo como esto.

.. figure:: ../images/horizon/start.jpg

Autentique usando las credenciales de admin o demo, para obtener la clave seria en el **nodo controller**
::

	# awk -F= '/ADMIN/ {print $2}' password-table.sh 
	95cd5b195e855fc0bdbe

Cuidado el codigo generado es aleatorio, no sera igual al que usted tiene.

.. figure:: ../images/horizon/admin.jpg

Hasta aqui vemos que si funciona realmente las guías de `OpenStack <http://docs.openstack.org/kilo/install-guide/install/apt/content/>`_  
vamos muy bien...!!!


Continuamos trabajando...!!!
