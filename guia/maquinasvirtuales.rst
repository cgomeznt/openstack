Maquinas Virtuales en virtualbox
================================

Tenemos como host un Debian Jessie 8.0 e instalado un virtualbox 5.0.4, en virtual box debe crear tres (3)  maquinas virtuales en Ubuntu 14.04.4 trusty server.

Cada una de las maquinas virtuales les otorgamos

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
* Se le instalo a cada maquina openssh-server y git.

Es más que suficiente, tenga mucho cuidado con la configuración de los adaptadores de red esto es vital.

Listo...!!! 


