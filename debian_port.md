# How to port new software to old system?
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

Before you can successfully build the package, you need to change some package version and names to suit the condition of your old distribution.

```shell
dpkg-buildpackage -uc -us -j4
```