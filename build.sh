#!/bin/bash
set -e -x
echo "hello world"
cd ~/slurm-llnl-18.08.5.2
# https://gitee.com/freewind201301/slurm-llnl-18.08
git rev-parse --verify HEAD
dpkg-buildpackage -uc -us

