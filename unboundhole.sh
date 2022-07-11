#! /bin/sh

## Check for system updates.

sudo apt update &

wait

## Perform full upgrade.

sudo apt full-upgrade -y &

wait

## Switch to opt folder to download whitelist scripts.

cd /opt/

## Download whitelist scrips for pihole.

sudo git clone https://github.com/anudeepND/whitelist.git 

## Install Unbound package.

sudo apt install unbound sqlite3 -y

## Download and install root.hints file for unbound.

wait

wget https://www.internic.net/domain/named.root -qO- | sudo tee /var/lib/unbound/root.hints 

## Complete unbound config including tweaks

wait

sudo cp pi-hole.conf /etc/unbound/unbound.conf.d/pi-hole.conf

## Configure dnsmasq packet size cap.

wait

sudo mkdir /etc/dnsmasq.d/

sudo cat <<EOF >/etc/dnsmasq.d/99-edns.conf
edns-packet-max=1232
EOF

## Configure Cron to update Root Hints and Whitelist files.

wait

sudo cp crontab /etc/crontab

## Configure NTP for DNSSec

sudo cat <<EOF >/etc/systemd/timesyncd.conf
FallbackNTP=194.58.204.20 pool.ntp.org
EOF

## Restart unbound after config changes.

wait

sudo systemctl restart unbound

wait

## Install Pihole

sudo curl -sSL https://install.pi-hole.net | bash

wait

## Modifier to disable cache and DNS sec. Switches DNS to Unbound instance.

sudo cp 01-pihole.conf /etc/dnsmasq.d/01-pihole.conf

## Config to ensure settings remain through updates

wait

sudo cp setupVars.conf /etc/pihole/setupVars.conf

## Tweaks for Pihole-FTL

wait

sudo cp pihole-FTL.conf /etc/pihole/pihole-FTL.conf

## Add more lists to pihole

sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts', 1, 'SteveBlack');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt ', 1, 'SimpleTrackers');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt', 1, 'SimpleAds');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts_without_controversies.txt', 1, 'KADHosts');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts', 1, 'FadeMind');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://v.firebog.net/hosts/static/w3kbl.txt', 1, 'Firebog w3kbl');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://v.firebog.net/hosts/AdguardDNS.txt', 1, 'Adguard');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://v.firebog.net/hosts/Admiral.txt', 1, 'Admiral');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt', 1, 'WindowsSpyBlocker');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts', 1, 'FadeMind Extras');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-blocklist.txt', 1, 'NoTrack');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://v.firebog.net/hosts/Prigent-Ads.txt', 1, 'PrigentAds');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://v.firebog.net/hosts/Easyprivacy.txt', 1, 'EasyPrivacy');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts', 1, 'BigDargon');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts', 1, 'FadeMind Unchecky');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext', 1, 'Yoyo');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://v.firebog.net/hosts/Easylist.txt', 1, 'Firebog Easy');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt', 1, 'AnudeepND');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt ', 1, 'FirstParty');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt', 1, 'MalwareHosts');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt', 1, 'OSINT Threat');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt', 1, 'Malvertising');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://v.firebog.net/hosts/Prigent-Crypto.txt', 1, 'Prigent Crypto');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://bitbucket.org/ethanr/dns-blacklists/raw/8575c9f96e5b4a1308f2f12394abd86d0927a4a0/bad_lists/Mandiant_APT1_Report_Appendix_D.txt', 1, 'Mandiant');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://phishing.army/download/phishing_army_blocklist_extended.txt', 1, 'Phishing');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt', 1, 'Notrack Malware');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://v.firebog.net/hosts/Shalla-mal.txt', 1, 'Shallamal');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt', 1, 'Spam404');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts', 1, 'Fademind AddRisk');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://urlhaus.abuse.ch/downloads/hostfile/', 1, 'AbuseCH');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser', 1, 'Coinblocker');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://dbl.oisd.nl/', 1, 'DBL OISD');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://zerodot1.gitlab.io/CoinBlockerLists/hosts', 1, 'Coinblocker');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/StevenBlack/hosts/master/data/add.Risk/hosts', 1, 'StevenBlack AddRisk');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://v.firebog.net/hosts/Prigent-Phishing.txt', 1, 'Prigent Phishing');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://v.firebog.net/hosts/Prigent-Malware.txt', 1, 'Prigent Mal');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/StevenBlack/hosts/master/data/add.2o7Net/hosts', 1, 'Ad2o7Net');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/StevenBlack/hosts/master/data/UncheckyAds/hosts', 1, 'Unchecky Ads');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/StevenBlack/hosts/master/data/add.Spam/hosts', 1, 'StevenBlack Spam');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/StevenBlack/hosts/master/data/KADhosts/hosts', 1, 'StevenBlack KAD');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://reddestdream.github.io/Projects/MinimalHosts/etc/MinimalHostsBlocker/minimalhosts', 1, 'MinimalHosts');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('http://sysctl.org/cameleon/hosts', 1, 'Chameleon');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://codeberg.org/Jeybe/pi-hole-blocklists/raw/branch/master/blocklist.txt', 1, 'Jeybe');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://pgl.yoyo.org/adservers/serverlist.php?hostformat=nohtml', 1, 'yoyo Adservers');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://codeberg.org/Jeybe/pi-hole-blocklists/raw/branch/master/blocklist.txt', 1, 'SomeoneWhoCares');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/Dawsey21/Lists/master/main-blacklist.txt', 1, 'Dawsey');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://www.stopforumspam.com/downloads/toxic_domains_whole.txt', 1, 'ToxicDomains');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://gist.githubusercontent.com/BBcan177/4a8bf37c131be4803cb2/raw', 1, 'BBCan177');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://s3.amazonaws.com/lists.disconnect.me/simple_malware.txt', 1, 'SimpleMal');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('http://theantisocialengineer.com/AntiSocial_Blacklist_Community_V1.txt', 1, 'AntiSocial');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt', 1, 'DeveloperDan');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt', 1, 'KADHosts PolishFilters');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/Kees1958/W3C_annual_most_used_survey_blocklist/6b8c2411f22dda68b0b41757aeda10e50717a802/TOP_EU_US_Ads_Trackers_HOST', 1, 'Surveylist');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://hosts.oisd.nl/', 1, 'hosts oisd');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://dnsmasq.oisd.nl/', 1, 'dnsmasq oisd');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://winhelp2002.mvps.org/hosts.txt', 1, 'Winhelp');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/chadmayfield/my-pihole-blocklists/master/lists/pi_blocklist_porn_top1m.list', 1, 'Porn1m');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://v.firebog.net/hosts/Prigent-Adult.txt', 1, 'Prigent Adult');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/mhhakim/pihole-blocklist/master/list.txt', 1, 'mhhakim');"
sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('https://raw.githubusercontent.com/mhhakim/pihole-blocklist/master/porn.txt', 1, 'mhhakim Porn');"
## sudo sqlite3 /etc/pihole/gravity.db "INSERT INTO adlist (address, enabled, comment) VALUES ('', 1, '');"
## ^^^ Placeholder reference to add more lists ^^^

wait

## Update gravity db

sudo pihole -g &

wait

## Move to Whitelist Directory

cd /opt/whitelist/scripts

## Run Whitelist script for first time. (Cron will run this on schedule)

sudo python whitelist.py &

wait

## Restart system

sudo reboot
