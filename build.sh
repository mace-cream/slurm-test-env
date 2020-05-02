#!/bin/bash
set -e -x
cd ~/
# remove old deb file
find ./ -maxdepth 1 -name "*.deb" | grep 18.08.5.2 | xargs rm -f
# get source
apt-get source slurm-llnl
cd slurm-llnl-18.08.5.2
# change the version of deps
sed -i 's/11/9/g' ./debian/control
sed -i 's/default-libmysql/libmysql/g' ./debian/control
dpkg-buildpackage -uc -us
cd ..
# list artifact
find ./ -maxdepth 1 -name "*.deb" | grep 18.08.5.2
# Raspbian 8 uses debian jessie, whose gcc version is 4.9.
# GitHub action bundles a higher version of node
# which the default system libstdc++ does not support.
# Therefore it is impossible to use @actions/xxx, which
# uses node to execute JS code.
# Theoreticially it is possible to hard coded the upload
# code using the restful api.
# See https://github.com/actions/toolkit/blob/57d20b4db494c25af8d2f3d9323650044610e531/packages/artifact/src/internal/utils.ts#L216
# But it may change since it is internally used by GitHub.
# Manually uploaded artifect can be found at
# https://bintray.com/zhaofeng-shu33/raspbian8/slurm/18.08
