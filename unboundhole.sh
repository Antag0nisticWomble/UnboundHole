#!/bin/bash
# Filename: Unboundhole.sh
# Version: 1.3
# Creation: 2 Sept 2022
# Author: Antag0nisticWomble

## Reference Functions

source varFunc.sh

## Log output

mkdir logs
exec > >(tee -a "$log_location/$currentHost-$dateTime".log)
exec 2>&1

## Check OS

if [ "$(hostnamectl | grep -oE 'Ubuntu')" = 'Ubuntu' ]
    then
        echo -e "$INFO Ubuntu Detected proceeding. $END" 
        bash ubuntu.sh
fi
if [ "$(hostnamectl | grep -oE 'Debian')" = 'Debian' ]
    then
        echo -e "$INFO Debian Detected Proceeding $END"
        bash debian.sh
fi
if [ "$(hostnamectl | grep -oE 'CentOS')" = 'CentOS' ]
    then 
        echo -e "$INFO CentOS Detected Proceeding $END"
        bash centos.sh
fi
if [ "$(hostnamectl | grep -oE 'Fedora')" = 'Fedora' ]
    then
        echo -e "$INFO Fedora Detected Proceeding $END"
        bash fedora.sh
fi
