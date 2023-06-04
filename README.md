# UnboundHole #

A simple pihole + unbound install script.

Please be warned the community lists included with this config amount to over 7 million addresses, you may have to manually whitelist some sources. 
I don't use social media so a lot of these are included in the lists. Pornography is also blocked by the lists inclueded in this script. You have been warned!

This script is a work in progress so you may encounter issues.

## Tested and working instalations ##

Debian 10/11

Ubuntu 18.04/20.04/22.04/22.10

Pi OS Bullseye

## Important ##

Be sure that you leave DNSSEC and cache disabled on pihole as this will be handled by unbound and turning them on can cause issues.
The script will automatically disable these features in pihole.

## One liner to get you started. ##
wget https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/stable/unboundhole.sh && chmod +x unboundhole.sh && ./unboundhole.sh

On the pihole installation menu set DNS servers to custom and input 127.0.0.1#5335 this is to make sure pihole queries unbound for addresses.
