#!/bin/bash
# Filename: Unboundhole.sh
# Version: 1.2
# Creation: 1 Sept 2022
# Author: Antag0nisticWomble

log_location="${PWD%/}/logs"

# Functions

function sig_check(){
    echo -e "$INFO Checking DNSSEC is working $END"
        if [ "$(dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335 | grep -oE 'SERVFAIL')" = 'SERVFAIL' ]
            then
                echo -e "$GOOD Bad signature test passed successfully. $END"
            else
                echo -e "$ERROR Bad signature test failed. Issue with Unbound installation please report your fault along with the log files generated in 
                $log_location $END"
        fi
        if [ "$(dig sigok.verteiltesysteme.net @127.0.0.1 -p 5335 | grep -oE 'NOERROR')" = 'NOERROR' ]
            then
                echo -e "$GOOD Good signature test passed successfully. $END"
            else
                cat /var/log/syslog | grep -i unbound > $log_location/unbound.log
                echo -e "$ERROR Good signature test faied. Issue with Unbound installation pplease report your fault along with the log files generated in 
                $log_location $END"
                exit
        fi
        if [ "$(dig google.com 127.0.0.1 -p 53 | grep -oE 'NOERROR')" = 'NOERROR' ]
            then    
                echo -e "$GOOD Pihole test complete. Installation complete. $END"
            else
                cat /var/log/syslog | grep -i pihole > $log_location/pihole.log
                echo -e "$ERROR Issue with installation please report your fault along with the log files generated in 
                $log_location. $END"
                exit
        fi
}

function whitelist(){
    cd /opt/
    
    ## Download whitelist scrips for pihole.
    echo -e "$WARN Install whitelist script. $END"
    sudo git clone https://github.com/anudeepND/whitelist.git 
    
    # Remove clear console line.
    sudo sed -i '87s/.*/ /' /opt/whitelist/scripts/whitelist.py

    ## Move to Whitelist Directory.

    cd /opt/whitelist/scripts

    ## Run Whitelist script for first time. (Cron will run this on schedule).

    echo -e "$WARN Starting whitelist script. $END"
    sudo ./whitelist.py
    echo -e "$GOOD Script completed successfully. Proceeding to test DNSSEC. $END"
}

function gravity_up(){
    echo -e "$INFO Pulling in new lists into gravity. $END"
    sudo pihole -g
    echo -e "$GOOD Lists updated successfully. $END"
}

function adlists(){
    echo -e "$INFO Adding new lists to database. $END"
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
    echo -e "$GOOD New adlists added to database. $END"
}

function ftl_tweaks(){
    echo -e "$INFO Adding tweaks to pihole-FTL. $END"
    sudo sed -i '$ a ANALYZE_ONLY_A_AND_AAAA=true' /etc/pihole/pihole-FTL.conf
    sudo sed -i '$ a MAXDBDAYS=90' /etc/pihole/pihole-FTL.conf
    echo -e "$GOOD Pihole FTL config complete. $END"
}

function config_persist(){
    echo -e "$WARN Making pihole config persistent. $END"
    sudo sed -i 's/CACHE_SIZE=10000/CACHE_SIZE=0 /' /etc/pihole/setupVars.conf
    echo -e "$GOOD Config changes saved. $END"
}

function pihole_conf(){
    echo -e "$INFO Disabling pihole cache. $END"
    sudo sed -i 's/cache-size=10000/cache-size=0 /' /etc/dnsmasq.d/01-pihole.conf
    echo -e "$GOOD Pihole cache disabled. $END"
}

function pihole(){
    sudo systemctl restart unbound
    echo -e "$INFO Beginning pihole installation. $END"
    sudo curl -sSL https://install.pi-hole.net | sudo PIHOLE_SKIP_OS_CHECK=true bash
    echo -e "$INFO Pihole successfully installed. $END"
}

function timesync_conf(){
    echo -e "$INFO Updating NTP Server configuration $END"
    sudo sed -i '$ a FallbackNTP=194.58.204.20 pool.ntp.org/' /etc/systemd/timesyncd.conf
    echo -e "$GOOD NTP servers updated. $END"
}

function update_crontab(){
    echo -e "$WARN Updating Crontab. $END"
    sudo sed -i '$ a 0 1 * * */7     root    /opt/whitelist/scripts/whitelist.py' /etc/crontab
    sudo sed -i '$ a 05 01 15 */3 *  root    wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root' /etc/crontab
    sudo sed -i '$ a 10 01 15 */3 *  root    service unbound restart' /etc/crontab
    echo -e "$GOOD Crontab Updated. $END"
}

function unboundconf(){
    echo -e "$INFO Installing unbound configuration. $END"
    sudo cp ${PWD%/}/pi-hole.conf /etc/unbound/unbound.conf.d/
    echo -e "$GOOD Unbound configuration installed. $END"
}

function root_hints(){
    echo -e "$INFO Downloading and installing root hints file. $END"
    wget https://www.internic.net/domain/named.root -qO- | sudo tee /var/lib/unbound/root.hints
    echo -e "$GOOD Root hints file successfully installed. $END"
    echo -e " "
    echo -e " "
}

function unbound_prereq(){
    echo -e "$INFO Installing required packages. $END"
    sudo apt install curl git unbound sqlite3 -y
    echo -e "$GOOD Packages installed. $END"
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

function system_upgrade(){
    read sys_upgrade_yn
        case $sys_upgrade_yn in
            [yY])
                echo -e "$WARN Proceeding to upgrade.$END"
                echo -e "$INFO Fetching latest updates. $END"
                sudo apt update
                echo -e "$INFO Downloading & installing any new packages. $END"
                sudo apt full-upgrade -y -q
                echo -e "$INFO Performing snap refresh. $END"
                sudo snap refresh
                echo -e "$GOOD System upgrades complete! $END"
                echo -e "$INFO Would you like to reboot the system now? Y/N $END"
                sys_reboot
                ;;
            [nN])
                echo -e "$ERROR Please update and reboot system then try again. $END"
                exit 0
                ;;
        esac
}

function check_updated(){
    echo -e "$INFO Is the system fully updated? [Y / N] $END"
        read sys_updated_yn
            case $sys_updated_yn in
                [yY])
                    echo -e "$GOOD Continuing to installation Phase. $END"
                    unbound_prereq
                    ;;
                [nN])
                    echo -e "$WARN Would you like to upgrade the system now? Y/N $END"
                    system_upgrade
                    ;;
            esac
}
