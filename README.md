# UnboundHole #
Self install script for pihole with unbound using community lists and AnudeepND whitelist script.

A simple pihole + unbound install script. All files are commented in sections for those curious as to what the script is doing and the pihole configs can be adjusted as you see fit.
Just be sure that you leave DNSSEC and cache disabled on pihole this will be handled by unbound and turning them on can cause issues.

Please be warned the community lists included with this config amount to over 7 million addresses, you may have to manually whitelist some sources. 
I don't use social media so a lot of these are included in the lists. You have been warned!

On the pihole installation menu set DNS servers to custom and input 127.0.0.1#5335 this is to make sure pihole queries unbound for addresses.

## One liner to get you started ##
sudo git clone https://github.com/Antag0nisticWomble/UnboundHole.git && cd UnboundHole/ && sudo chmod +x unboundhole.sh && sudo ./unboundhole.sh -V
