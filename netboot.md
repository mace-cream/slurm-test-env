# How to set-up network boot?
To do this, first you need a server computer runing `tftp` and `dhcp` service and your local client computer is connected to the same network with the server computer.

We use Ubuntu 19.04 as an example and serve the debian `netboot` installer as an example.

## TFTP
install `tftpd-hpa` and the service root directory is `/var/lib/tftpboot/`.

Download `netboot.tar.gz` from official mirror.

## DHCP
