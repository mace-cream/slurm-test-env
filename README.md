## Computer

| architecture | operating system | ip address  | hostname           | slurm version | 
|--------------|------------------|-------------|--------------------|---------------|
| x86_64       | CentOS 7.7       | 10.8.15.207 | zhiyuanWorkstation | 19.05         |
| x86_64       | Fedora 30        | 10.8.15.92  | zhaofengLapTop     | 19.05         |
| armhf        | Raspbian 8       | 10.8.15.90  | raspberrypi        | 19.05         |

`zhiyuanWorkstation` is the manage node.

## Test User
The users exist on all computers list above.

| username  | passwd      | uid  | gid  |
|-----------|-------------|------|------|
| zhaofengt | fengzhao    | 1010 | 1010 |
| zhiyuant  | qinghua2019 | 1011 | 1011 |


`zhaofengt` is the user with sudo privilege. You can login to the computers through `ssh` if you are on the 15th floor of C2, Nanshan Park.

[Installation Guide](https://www.slothparadise.com/how-to-install-slurm-on-centos-7-cluster/)


## Test Command
On manage node, use the following command to test that the whole system works.
```shell
srun hostname
```

## Known Issues
* `slurmd` cannot be started as system daemon service on `zhaofengLapTop`. 
* `firewalld` should be disabled on all machines.

## How to create user with the same UID and GID on same machine?
```shell
sudo groupadd -g 1010 zhaofengt
sudo useradd -d /home/zhaofengt -g zhaofengt -u 1010 -s /bin/bash -m zhaofengt
sudo passwd zhaofengt
```

## Firewall
Check the opening port
```shell
sudo firewall-cmd --list-ports
```
## Available binary for CentOS 7
See [copr](https://copr.fedorainfracloud.org/coprs/cmdntrf/Slurm19-nvml/package/slurm/)


## job Queue
zhaofeng's laptop only has two physical cpus. The number of logical cpus is 4 due to hyperthreading. Only two jobs are allowed to run simultaneously. The third job should 
wait.

