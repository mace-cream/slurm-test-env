# How to make a computing cluster using slurm

Author: Feng Zhao, Zhiyuan Wu

You may hear about the concept of computing cluster, which consists of one manage node and several compute nodes basically. 
Users login to manage node and submit their computing tasks using a workload manager. 
Cluster management is more difficult than management of a single multi-user computer. 
It is beneficial for cluster manager if they install the computing cluster by themselves. 
If you want to try to build a test environment of computing cluster and you have several “computers” at hand, this tutorial will suit your need.


## Before you start
In this tutorial, We will use existing resources in our lab: 
one workstation desktop running Ubuntu operating system, one laptop running Ubuntu and two Raspberry Pi boards. 
That is, We have 4 "computers" in total. 
Since you may not have the same resources as us, 
some details may be different. But the general workflow to configure the cluster is the same. 

[Raspberry Pi](https://www.raspberrypi.org/) is a tiny computer used in embedding systems. 
It runs on arm architecture while our PCs run on x64 architecture. 
We will use the workstation desktop as the manage node for the cluster and the left three as compute nodes. 
Generally speaking, in production environment we should use the same architecture and operating system to build a cluster. 
But for our test environment, we don't follow this and use the existing operating system on each machine to achieve our goal.

The exact configuration is shown in the following table:

| architecture | operating system | ip address  | hostname           | slurm version | slurm config file          |
| ------------ | ---------------- | ----------- | ------------------ | ------------- | -------------------------- |
| x86_64       | Ubuntu 19.04     | 10.8.15.207 | zhiyuanWorkstation | 18.08         | /etc/slurm-llnl/slurm.conf |
| x86_64       | Ubuntu 19.04     | 10.8.15.92  | zhaofengLapTop     | 18.08         | /etc/slurm-llnl/slurm.conf |
| armhf        | Raspbian 8       | 10.8.15.88  | raspberrypi        | 18.08         | /etc/slurm-llnl/slurm.conf |
| armhf        | Raspbian 10      | 10.8.15.87  | raspberrypi2       | 18.08         | /etc/slurm-llnl/slurm.conf |

Building a cluster can be divided into three big steps in general:

1. connect your computer to the same local network
1. installation of software 
1. configuration the cluster

Our goal is to build a cluster for high performance computing (HPC) purpose. The cluster architecture for other domains may be different. For example,
workload manager may not be needed. You can skip step 3 if you do not need it.

Below we will show in detail how I finish the three steps.

## Connection
To make the cluster more stable, we use wired cable to connect each computer to a mini switch. You can buy one which has 5 Ethernet interfaces  from the market. 
You should document the ip address of each computer for later usage.
Since I use `zhiyuanWorkstation` as the manage node, which has the monitor connected to the host, I can login to this host locally with the keyboard.
After logging in to the manage node. We use `ping` command to test the network connection between the manage node and each compute node. For example,
use `ping -c 4 10.8.15.92` to test for `zhaofengLapTop`.

## Installation

Since you are only building a test environment in intranet, you can disable the firewalls to avoid later trouble. The security vulnerability overhead is little as you can enable the firewall later on. You can also not disable this service but open some ports instead. We omit this configuration.

Although we use heterogeneous operating systems, they are all debian-based, which means the package name is identical. `apt` is the manager. I recommend you to install `openssh-server` on all nodes to ease the configuration. Since you do not need to connect a display monitor, mouse and keyboard to each device for local login to configure the device. The requirement is to install `slurmctld` and `slurmd` package on your chosen manage node and `slurmd` on other nodes.

 Installation of software using `apt` is easy, just type `sudo apt install package_name` and you are done.

There is a special case for slurm on Raspbian 8. You can omit this paragraph if you choose to upgrade your system. If not, you can not use the default slurm version, which is 14.03 and too old. You should compile slurm 18.08 from source on Raspbian 8.
This is not an easy task. To omit this step, we have packed the binary artifact in deb format. All you should do is all our apt source, update and install slurm 18.08 on the fly:

```shell
echo "deb https://dl.bintray.com/zhaofeng-shu33/raspbian8/ jessie contrib" > /etc/apt/sources.list.d/jessie-slurm.list
apt-get update
apt install slurmd=18.08 # for raspbian 8
```
## Configuration
### openssh-server

If you install `openssh-server`, you need to configure it to ease the configuration of other softwares. For example, you can set ssh login without password using the following command:

```shell
ssh-keygen -t rsa # generated public and private keys in ~/.ssh/
ssh-copy-id zhaofengt@raspberrypi # use the ip address of raspberrypi instead
```

### Test User

When installing new softwares, we act as a sudo user. But for our computing cluster to work, we need to ensure that users with the same name, user id and group id exists on all nodes.

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
`Munge` is the authentication library used by slurm extensively. You need to make sure `munge` work before you proceed to configure slurm itself. Generally there are two steps to configure the munge:

1. generate `munge.key` and copy it to all nodes
2. start the `munge` service on all nodes

To generate `munge.key`, using the following command:
```shell
dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key
echo "foo" >/etc/munge/munge.key
```

The `munge.key` should be the same on all machines. You can use `scp` to transfer this file to other machines on the same location. You need to change `munge.key` permission to `400`, which means only file owner can read this file; also the owner and group for `munge.key` should be `munge`.

```shell
sudo chmod 400 /etc/munge/munge.key
sudo chown munge /etc/munge/munge.key
sudo chgrp munge /etc/munge/munge.key
```



Then use the following command to start the munge daemon and make sure it works:

```shell
sudo systemctl start munge
systemctl status munge
sudo journalctl -u munge -r # reverse
```

If any service does not work, you can use `journalctl` to check its message, similar as above.

If you have configured openssh, you can check whether munge works across nodes:

```shell
unmunge | ssh raspberrypi munge -n
```

### Configure slurm

Slurm has two configuration files: `slurm.conf` and `cgroup.conf`. They are located in `/etc/slurm-llnl/`.
The content of these two files should be the same on all machines.
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
After creating the files on manage node. Copy these two files to each compute node at the specific location. Then you can start the daemon process on each node.
The service name is called `slurmctld` on manage node and `slurmd` on computing node. This is similar with how you start the `munge` daemon process.


### Test Command
After all daemon process started, you can test the computing cluster using test account. First, ssh login to the manage node using `zhaofengt`.
On manage node, use the following command to test that the whole system works.

```shell
srun -w zhaofengLapTop hostname
srun -w raspberrypi,raspberrypi2 /bin/hostname
sbatch --array=0-9 job.sh
```
If `python3` is installed on all computing nodes. The content of `job.sh` is as follows:
```shell
#!/bin/bash
python3 -c "import time;time.sleep(30)"
```




# Reference
1. [Munge Installation-Guide](https://github.com/dun/munge/wiki/Installation-Guide)
1. [Slurm Installation-Guide](https://slurm.schedmd.com/quickstart_admin.html)
