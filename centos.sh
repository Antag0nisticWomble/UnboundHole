#!/bin/bash
# Filename: centos.sh
# Version: 1.3
# Creation: 2 Sept 2022
# Author: Antag0nisticWomble

source varFunc.sh

function unbound_prereq(){
    echo -e "$INFO Installing required packages. $END"
    echo -e " "
    sudo yum install curl git unbound sqlite3 -y
    echo -e "$GOOD Packages installed. $END"
    echo -e " "
    root_hints
}

function sys_reboot(){
    read sys_reboot_yn
        case $sys_reboot_yn in
            [yY])
                echo -e "$WARN system rebooting in 10 seconds! $END"
                sleep 10
                sudo reboot
                ;;
            [nN])
                echo -e "$INFO Please restart the script once system has rebooted. $END"
                exit 0
                ;;
        esac
}

function centos_upgrade(){
    read centos_upgrade_yn
        case $centos_upgrade_yn in
            [yY])
                echo -e "$WARN Proceeding to upgrade.$END"
                echo -e " "
                echo -e "$INFO Fetching and installing latest updates. $END"
                echo -e " "
                sudo yum update -y
                echo -e " "
                echo -e "$GOOD System upgrades complete! $END"
                echo -e " "
                echo -e "$INFO Would you like to reboot the system now? Y/N $END"
                sys_reboot
                ;;
            [nN])
                echo -e "$ERROR Please update and reboot system then try again. $END"
                exit 0
                ;;
        esac
}


echo -e "$INFO Is the system fully updated? [Y / N] $END"
    read centos_updated_yn
        case $centos_updated_yn in
            [yY])
                echo -e "$GOOD Continuing to installation Phase. $END"
                echo -e " "
                unbound_prereq
                ;;
            [nN])
                echo -e "$WARN Would you like to upgrade the system now? Y/N $END"
                echo -e " "
                centos_upgrade
                ;;
        esac


## Install prerequisites

unbound_prereq

## Install unbound configuration

unboundconf

## Add whitelist script and root hints update to cron

update_crontab

## Setup time servers for unbound

timesync_conf

## Install pihole

pihole

## Disable pihole cache and dnssec

pihole_conf

## Make pihole config persistent

config_persist

## Tweal FTL for better performance with unbound

ftl_tweaks

## Add community adlists to gravity

adlists

## Update gravity database

gravity_up

## Pull in whitelist scripts

whitelist

## Check Unbound DNSSEC and Pihole are functioning correctly

sig_check

## Password Reminder.

echo -e "$GOOD Installation complete.$END""$WARN Remember to run sudo pihole -a -p to change your password. $END"
