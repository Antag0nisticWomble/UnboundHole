#!/bin/bash
# Filename: Unboundhole.sh
# Version: 1.2
# Creation: 1 Sept 2022
# Author: Antag0nisticWomble

# Output Formatting

ERROR='\033[1;91m'  #  -> RED
GOOD='\033[1;92m'   #  -> GREEN
WARN='\033[1;93m'   #  -> YELLOW
INFO='\033[1;96m'   #  -> BLUE
END='\033[0m'       #  -> DEFAULT

# Output Variables

currentUser=$(whoami)
currentHost=$(hostname)
dateTime=$(date +"%Y-%m-%d %T")
log_location="${PWD%/} logs"

# Log output

exec > >(tee -a "$log_location/$currentHost-$dateTime".log)
exec 2>&1

# Reference Functions

source varFunc.sh

## Check Updated

check_updated

## Install Unbound

unbound_prereq

## Download root hints file

root_hints

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
