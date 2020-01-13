We consider Ubuntu desktop >= 18.04 with gnome desktop. The DNS and network has envolved and many pieces online does not fit anymore.

## NetworkManager

Currently, the desktop network is controlled by `NetworkManager`, which is the service name also.

The configuration file is at the directory: `/etc/NetworkManager/system-connections/`. The important part is

```
[ipv4]
method=auto
```

The configuration part is persistent after rebooting. The temporary files which store the current setting is located at
`/var/lib/NetworkManager`. 

All the above comes from the package `network-manager`.

Usually the user does not need to modify the configuration file by hand; The GUI program `nm-connection-editor`(comes from package network-manager-gnome) provides a useful interface to edit configuration file of `NetworkManager`. Notice that to make the changes appliable. We should restart the `NetworkManager` daemon in some cases.