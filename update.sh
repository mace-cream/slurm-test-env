#!/bin/bash
wget http://10.8.4.170:88/zhaofeng-shu33/slurm-test-env/raw/master/slurm.conf?inline=false -O slurm.conf
if [[ "$(hostname)" = "zhaofengLaptop" ]]; then 
	sudo mv ./slurm.conf /etc/slurm/
else
	sudo mv ./slurm.conf /etc/slurm-llnl/
fi

