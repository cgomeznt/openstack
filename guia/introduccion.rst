Introducción
============

Primero que todo vamos a seguir paso a paso las guías de `OpenStack <http://docs.openstack.org/kilo/install-guide/install/apt/content/>`_ (por medio de los scripts), es decir, los scripts estan desarrollados por cada capitulo de la guía de OpenStack, por lo tanto se recomienda que primero lea la guías de OpenStack, que la tenga siempre a la mano y luego proceda con la practica.

En esta guía vamos a utilizar un Host con Debian Jessie y con virtualbox. Debemos tener creada en virtualbox tres (3) maquinas virtuales con Ubuntu 14.04.4 trusty. En estas maquinas virtuales podremos instalar cualquiera de las siguientes versiones de OpenStack (icehouse, juno, kilo o liberty), aquí vamos a empezar con kilo para trabajar con una mima guía, porque esta guía es exactamente igual para (icehouse y juno) pero para liberty hay cambios, por lo tanto vamos aprender lo anterior y luego aprendemos liberty que es lo nuevo y así tendremos dominio de todas las versiones de `OpenStack <http://docs.openstack.org/kilo/install-guide/install/apt/content/>`_.

En este laboratorio primero vamos a instalar  solo dos (2) de las maquinas virtuales para la siguiente arquitectura de nodos (nova-network)

* nodo controller
* nodo compute1

Luego en el siguiente laboratorio utilizaremos las tres (3) maquinas virtuales para la arquitectura de los siguientes nodos (neutron-network)

* nodo controller
* nodo network (neutron)
* nodo compute1

Antes de continuar prepare su laboratorio ya sea con equipos físicos o con maquinas virtuales como las vamos a trabajar aquí.

Para descargar el proyecto debe hacer lo siguiente::

	$ git clone https://github.com/cgomeznt/openstack.git

Luego puede continuar con

`Maquinas Virtuales en virtualbox <maquinasvirtuales.rst>`_



