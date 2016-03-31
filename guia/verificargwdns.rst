Verificar el gateway y DNS en los servidores
+++++++++++++++++++++++++++++++++++++++++++++
:

# ping -c 4 openstack.org
ping: unknown host openstack.org

vemos que no responde puede ser problemas con el gateway o DNS, vamos a verificar el gateway primero::

# netstat -r
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
192.168.1.0     *               255.255.255.0   U         0 0          0 eth1

Vemos que no tenemos un default gateway, vamos a configurarlo::

# route add default gw 192.168.1.1

Consultamos nuevamente y también la prueba del ping (ICMP)

# netstat -r
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
default         192.168.1.1     0.0.0.0         UG        0 0          0 eth1
192.168.1.0     *               255.255.255.0   U         0 0          0 eth1

:

# ping -c 4 openstack.org
ping: unknown host openstack.org

:

# ping -c 2 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=52 time=71.2 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=52 time=66.0 ms
--- 8.8.8.8 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1010ms
rtt min/avg/max/mdev = 66.063/68.631/71.200/2.581 ms

Responde por IP pero vemos que por nombre no, vamos a ver ahora la configuración de los DNS y agregamos de una el de google::

# echo nameserver 8.8.8.8 >> /etc/resolv.conf 

:

# cat /etc/resolv.conf
nameserver 192.168.1.1
nameserver 8.8.8.8

:

# ping -c 2 openstack.org
PING openstack.org (162.242.140.107) 56(84) bytes of data.
64 bytes from 162.242.140.107: icmp_seq=1 ttl=48 time=126 ms
64 bytes from 162.242.140.107: icmp_seq=2 ttl=48 time=125 ms
--- openstack.org ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 6258ms
rtt min/avg/max/mdev = 125.471/125.923/126.376/0.575 ms

Listo ...!!! podemos continuar


