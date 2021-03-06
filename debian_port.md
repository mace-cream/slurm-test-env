# How to port new software to old system -- Build Slurm 18.08 on Debian Jessie

Suppose you are using debian 8. The default version of slurm is only 14, which is too old. To use a newer version, you can download the source code from 
the official website of slurm and build from source code. Then you can install it. This procedure is ok but it has two problems:

1. Installed software is hard to remove since there are not managed by system package manager
1. You can not share your build artifact with others in an easy way.

To solve the above two problems, you can first build the `deb` file and everyone can install it easily on the same operating system.

You do not need to write the debian rules by yourself, just download the source debian package from a newer version of debian distribution.

Firstly you need to add the source package channel

```
deb-src https://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ buster main contrib
```
We use mirror to speed up the download.

Then download the exact version for your package:
```shell
apt-get source slurm-llnl=18.08.5.2-1
```

The version of the slurm source package can be checked by `apt-cache showsrc slurm-llnl`.

Before you can successfully build the package, you need to change some package version and names to suit the condition of your old distribution. At the project root directory:
```
# deb-helper >= 9
sed -i 's/11/9/g' ./debian/control
# libmysql-dev
sed -i 's/default-libmysql/libmysql/g' ./debian/control
```

```shell
dpkg-buildpackage -uc -us -j4
```

## Important Notice:
   To compile `slurm 18.08` successfully on `jessie`. You need to upgrade `debhelper` to 10.2. For raspbian, it seems that the version is already 10.2 (I guess raspbian merges jessie backports to the main).
   But for normal jessie distribution, you should install `debhelper 10.2` from `jessie backports` explicitly.
```shell
echo "deb http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
apt-get -o Acquire::Check-Valid-Until=false update
apt-get install -t jessie-backports install debhelper # will upgrade the version
```
```

## Notice about qemu vm
If qemu virtual machine of debian jessie is used to build the package, jessie-backport of `debhelper`
needs to be installed.
Besides, there seems to be a strange problem related with twice running of `reconfigure` which will
cause the build error. To bypass this problem within qemu vm, we can
run `fakeroot dh binary` directly to bypass `dh build`. This way can also generate
deb packages successfully within qemu vm.

## Build log
[Official build log](http://buildd.raspbian.org/status/fetch.php?pkg=slurm-llnl&arch=armhf&ver=14.03.9-5%2Bdeb8u5&stamp=1584378384) for `slurm 14.03` on `jessie`;

Custom build log can be found on GitHub Action logs of this repo.
