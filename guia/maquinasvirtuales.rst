Maquinas Virtuales con virtualbox
================================

Tenemos como host a Debian Jessie 8.0 e instalado un virtualbox 5.0.4, en virtualbox debe crear tres (3) maquinas virtuales con Ubuntu 14.04.4 trusty server.

Cada una de las maquinas virtuales les otorgamos (trate que sean asi, para que pueda seguir el laboratorio sin problema)

* 800Mb de RAM.
* 1Mb de RAM de video.
* Se habilito en sistema, procesador, el PAE/NX.
* Se habilito en sistema, aceleración, el hardware de virtualización. 
* Se deshabilito el audio, los puertos en serie y los USB.
* El disco es SATA y tiene una capacidad de 20Gb.
* El adaptador de red se utilizarón tres (3) adaptadores.
	* Adaptador uno, conectado a Red Interna.
	* Adaptador dos, conectado a NAT.
	* Adaptador tres, conectado a Adaptador Puente.
* Se instalo Ubuntu 14.04.4 trusty server
* En la instalación se creo un usuario llamado **usuario** 
* Se le instalo a cada maquina openssh-server y git.

Es más que suficiente, tenga mucho cuidado con la configuración de los adaptadores de red esto es vital.

Listo...!!! 


