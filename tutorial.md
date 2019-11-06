# How to make a computing cluster using slurm

Author: Feng Zhao, Zhiyuan Wu

You may hear about the concept of computing cluster, which consists of one manage node and several compute nodes basically. 
Users login to manage node and submit their computing tasks using a workload manager. 
Cluster management is more difficult than management of a single multi-user computer. 
It is beneficial for cluster manager if they install the computing cluster by themselves. 
If you want to try to build a test environment of computing cluster and you have several “computers” at hand, this tutorial will suit your need.


## Before you start
In this tutorial, We will use existing resources in our lab: 
one workstation desktop running CentOS operating system, one laptop running Fedora and two Raspberry Pi boards. 
That is, We have 4 "computers" in total. 
Since you may not have the same resources as us, 
some details may be different. But the general workflow to configure the cluster is the same. 

[Raspberry Pi](https://www.raspberrypi.org/) is a tiny computer used in embedding systems. 
It runs on arm architecture while our PCs run on x86 architecture. 
We will use the workstation desktop as the manage node for the cluster and the left three as compute nodes. 
Generally speaking, in production environment we should use the same architecture and operating system to build a cluster. 
But for our test environment, we don't follow this and use the existing operating system on each machine to achieve our goal.

The exact configuration is shown in the following table:

| architecture | operating system | ip address  | hostname           | slurm version | slurm config file          |
|--------------|------------------|-------------|--------------------|---------------|----------------------------|
| x86_64       | CentOS 7.7       | 10.8.15.207 | zhiyuanWorkstation | 19.05         | /etc/slurm/slurm.conf      |
| x86_64       | Fedora 30        | 10.8.15.92  | zhaofengLapTop     | 19.05         | /etc/slurm/slurm.conf      |
| armhf        | Raspbian 8       | 10.8.15.88  | raspberrypi        | 19.05         | /etc/slurm-llnl/slurm.conf |
| armhf        | Raspbian 10      | 10.8.15.87  | raspberrypi2       | 18.08         | /etc/slurm-llnl/slurm.conf |

Building a cluster can be divided into three big steps in general:

1. connect your computer to the same local network
1. installation of software 
1. configuration the cluster

Our goal is to build a cluster for high performance computing (HPC) purpose. The cluster architecture for other domains may be different. For example,
workload manager may not be needed. You can skip step 3 if you do not need it.

Below we will show in detail how I finish the three steps.

## Connection
To make the cluster more stable, we use wired cable to connect each computer to the cable socket. 
You should document the ip address of each computer for later usage.
Since I use `zhiyuanWorkstation` as the manage node, which has the monitor connected to the host, I can login to this host locally with the keyboard.
After logging in to the manage node. We use `ping` command to test the network connection between the manage node and each compute node. For example,
use `ping -c 4 10.8.15.92` to test for `zhaofengLapTop`.

## Installation

The first step is to close the firewall service on the system. 
The service name is called `firewalld` on RHEL derivative. 
You can also not disable this service but open some ports instead. We omit this configuration.

Since we use heterogeneous operating systems, they have different package managers. For RHEL series, `yum` is the package manager.
For Debian series, `apt` is the manager instead. For the software we used, the two series may have different package names, which are
summarized in the following table.

| Software       | CentOS 7.7      | Fedora 30      | Raspbian 8          | Raspbian 10       |
|----------------|-----------------|----------------|---------------------|-------------------|
| openssh server | openssh-server  | openssh-server | openssh-server      | openssh-server    |
| munge          | munge           | munge          | munge               | munge             |
| slurm          | slurm-slurmctld | slurm-slurmd   | compile from source | slurmd            |
| python         | do not need     | python3        | python3.4-minimal   | python3.7-minimal |


Then we install the openssh server on all nodes. The service name is called `sshd` on
RHEL and `ssh` on Raspbian. The package name is called `openssh-server` on all distributions. Before ssh is installed, we need to use a monitor, mouse and keyboard to
connect to each node for this configuration. Use the following command to check whether the service is running:
```shell
systemctl status sshd
```

After the installation of openssh server, we can detect the monitor, mouse and keyboard from the computing node. Only power and network cable are necessary.
Then you can use the package manager to install `munge`, `slurm` and `python` on each platform. 
```shell
yum install munge # on CentOS 7.7 or Fedora 30
apt install munge # on Raspbian 8 or Raspbian 10
```

All is straightforward except for slurm on Raspbian 8. We can not use the default slurm version, which is 14.03 and too old. We should compile slurm 18.08 from source on Raspbian 8.
This is not an easy task. To omit this step, we have packed the binary artifact in deb format. All you should do is all our apt source, update and install slurm 18.08
on the fly:
```shell
echo "deb https://dl.bintray.com/zhaofeng-shu33/raspbian8/ jessie contrib" > /etc/apt/sources.list.d/jessie-slurm.list
apt-get update
apt install slurmd=18.08
```
## Configuration
### Test User
When installing new softwares, we act as a sudo user. But for our computing cluster to work, we need to ensure that users with the same name, user id and group id 
exists on all nodes.

We use the following two users:

| username  | passwd      | uid  | gid  |
|-----------|-------------|------|------|
| zhaofengt | fengzhao    | 1010 | 1010 |
| zhiyuant  | qinghua2019 | 1011 | 1011 |

With the example user `zhaofengt` and UID = GID = 1010, the command to create it is as follows:
```shell
sudo groupadd -g 1010 zhaofengt
sudo useradd -d /home/zhaofengt -g zhaofengt -u 1010 -s /bin/bash -m zhaofengt
sudo passwd zhaofengt
```
You should execute it on each node respectively.
### Configure Munge
Generally there are two steps to configure the munge:
1. generate `munge.key` and copy it to all nodes
2. start the `munge` service on all nodes

To generate `munge.key`, using the following command:
```shell
dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key
echo "foo" >/etc/munge/munge.key
```

The `munge.key` should be the same on all machines. You can use `scp` to transfer this file to other machines on the same location.

### Configure slurm
Slurm has two configuration files: `slurm.conf` and `cgroup.conf`. The location of `slurm.conf` is not all the same on different machines and is shown in previous table.
`cgroup.conf` should be put in the same directory of `slurm.conf`. The content of these two files should be the same on all machines.
The content of `slurm.conf` is as follows:
```
SlurmctldHost=zhiyuanWorkstation(10.8.15.207)
MpiDefault=none
ProctrackType=proctrack/cgroup
ReturnToService=1
SlurmctldPidFile=/var/run/slurmctld.pid
SlurmdPidFile=/var/run/slurmd.pid
SlurmdSpoolDir=/var/spool/slurmd
SlurmUser=root
StateSaveLocation=/var/spool
SwitchType=switch/none
TaskPlugin=task/affinity
SchedulerType=sched/backfill
SelectType=select/cons_res
SelectTypeParameters=CR_CPU
AccountingStorageType=accounting_storage/filetxt
AccountingStorageLoc=/var/log/slurm/accounting
ClusterName=cluster
JobAcctGatherType=jobacct_gather/linux
JobCompType=jobcomp/filetxt
JobCompLoc=/var/log/slurm/job_completions
NodeName=zhaofengLapTop NodeAddr=10.8.15.92 CPUs=4 State=UNKNOWN
NodeName=raspberrypi NodeAddr=10.8.15.88 CPUs=4 ThreadsPerCore=1 State=UNKNOWN
NodeName=raspberrypi2 NodeAddr=10.8.15.87 CPUs=4 ThreadsPerCore=1 State=UNKNOWN
PartitionName=debug Nodes=ALL Default=YES MaxTime=INFINITE State=UP OverSubscribe=YES
```
We use root user to run `slurmctld` on manage node, which is specified by `SlurmUser=root`.
The content of `cgroup.conf` is as follows:
```
CgroupAutomount=yes
ConstrainCores=yes
ConstrainRAMSpace=no
```

## Test Command
On manage node, use the following command to test that the whole system works.
```shell
srun -w zhaofengLapTop hostname
srun -w raspberrypi,raspberrypi2 /bin/hostname
sbatch --array=0-9 job.sh
```
The content of `job.sh` is as follows:
```shell
#!/bin/bash
python3 -c "import times;times.sleep(30)"
```

## Known Issues
* `slurmd` cannot be started as system daemon service on `zhaofengLapTop` and `raspberry`. Use `sudo slurmd` instead. No need to kill old `slurmd` as the newly start process will replace the old one automatically.
* `firewalld` should be disabled on all machines.
* IP addresses may change when you setup the whole system next time. Modify `slurm.conf` and DNS forward zone file `cluster.local.zone` correspondingly.


## Steps
Ideally, we should have a router, many wired lines and 4 computers. However, 
Resources are limited. We do not have control over the router and we do not have so many computers.
What we have is an environment of intranet, an old laptop with Fedora, a PC with CentOS and several Rasberry Pi 3B. Reinstalling the OS is time consuming and we omit this
step. As a result, we use heterogeneous architecture to build our cluster test environment.

1. Make sure all the nodes are physically connected in an intranet. To easy the configuration, the ssh server should be opened on all the nodes.  Create users `zhaofengt` and `zhiyuant` on all nodes. Make sure the users have the same UID and GID on different nodes.
1. `munge` should be installed on all nodes. See [Install Guide](https://github.com/dun/munge/wiki/Installation-Guide) for detail. The `munge.key` should be the same on all machines.
    This package can be installed using `apt` or `yum`.
1. Install `slurmctld` on manage node and `slurmd` on compute node. The version of `slurmctld` and `slurmd` may not be exactly the same, as announced by [slurm official](https://slurm.schedmd.com/troubleshoot.html#network).
   Since Debian 10 has officially packaged 18.8, we just install `slurmd` on Debian 10 using `apt` without compiling from source code. However, for Debian 8 the version is only 14. Therefore
   we should compile 19.5 from source code. Actually we do the compilation on the board (instead virtual machine) and notice that it is slow process.
1. The configuration file is generated using [configurator.easy](https://slurm.schedmd.com/configurator.easy.html). For our configuration, we use `root` to start
   `slurmctld`. That is, `SlurmUser=root`. We use `Cgroup` to track the process; therefore `cgroup.conf` should exist in the same directory of `slurm.conf`on all nodes.   
1. Other utilities can help administrators to manage the cluster. For example, we use ssh key to make `ssh raspberrypi` without password prompt; We setup a DNS server, the 
   setup file of forward zone can be found at this repository (`cluster.local.zone`). The service is called `named`, coming from `bind` package for RHEL. The DNS server is used
   to map the hostname to its ip address. To achieve this, we need add the DNS server entry in `/etc/resolv.conf`. We also use the `pdsh` utility (with gender database) to execute
   commands on multiple nodes. The test command is `pdsh -A python3 --version`. With this command, the output is as follows:
   ```
    [zhaofengt@zhiyuanWorkstation ~]$ pdsh -A python3 --version
    raspberrypi: Python 3.4.2
    zhaofengLaptop: Python 3.7.3
    raspberrypi2: Python 3.7.3
   ```
   Since the official package of `pdsh` on CentOS 7 does not support `gender` backend. We need to compile `pdsh` from source code and add `export PDSH_RCMD_TYPE=ssh` in our admin `.bashrc`.
   
Available binary for CentOS 7, see [copr](https://copr.fedorainfracloud.org/coprs/cmdntrf/Slurm19-nvml/package/slurm/)


## job Queue
zhaofeng's laptop only has two physical cpus. The number of logical cpus is 4 due to hyperthreading. Only two jobs are allowed to run simultaneously. The third job should 
wait.

## Tunneling
If you are not on 15th floor, assume the following command is executed on `zhiyuanWorkstation` and the session is kept.
```shell
ssh -R 10.8.4.170:8990:10.8.15.207:22 feng@10.8.4.170
```
Then you can login via
```shell
ssh -p 8990 zhaofengt@localhost # on bcm server
```

## Further experiment
With the test environment, we can submit some test jobs and observe the queue behaviour with `squeue`. We also test the job array functionality in our test environment.


# Reference
1. [Munge Installation-Guide](https://github.com/dun/munge/wiki/Installation-Guide)
1. [Slurm Installation-Guide](https://slurm.schedmd.com/quickstart_admin.html)
