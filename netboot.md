# How to set-up network boot?
To do this, first you need a server computer runing `tftp` and `dhcp` service and your local client computer is connected to the same network with the server computer.

We use Ubuntu 19.04 as an example and serve the debian `netboot` installer as an example.

## TFTP
install package `tftpd-hpa` and the service root directory is `/var/lib/tftpboot/`.

Download `netboot.tar.gz` from official mirror. For example [tuna](http://mirrors.tuna.tsinghua.edu.cn/debian/dists/buster/main/installer-amd64/current/images/netboot/netboot.tar.gz)

TFTP service will listen to port 69 for UDP traffic.

## DHCP
install package `isc-dhcp-server` and modify the configuration file `/etc/dhcp/dhcpd.conf` according to the following:

```
default-lease-time 600;
max-lease-time 7200;

allow booting;

DHCPDARGS="enp2s0";
server-name "zhiyuanWorkstation.cluster.local";
allow booting;
subnet 10.8.15.0 netmask 255.255.255.0 {
  range 10.8.15.59 10.8.15.61;
  option routers 10.8.15.254;
  option subnet-mask 255.255.255.0;
  option domain-name "cluster.local";
  option domain-name-servers 10.8.15.136, 10.8.4.200;
}
group {
  next-server 10.8.15.136;
  host zhaofengWorkstation {
    hardware ethernet f4:8e:38:ab:d8:fb;
    filename "pxelinux.0";
    server-name "zhiyuanWorkstation.cluster.local";
    fixed-address 10.8.15.60;
  }
}
```
Then start the `isc-dhcp-server` service daemon. The service will listen to port 67 for UDP traffic.

## Client
Enter BIOS setting and select NIC Booting as first option. Usually it is from Legacy Boot options.