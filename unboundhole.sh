#! /bin/sh

## Log output from script progress.
# export LOGDIR=./logs
# export DATE=`date +"%Y%m%d"`
# export DATETIME=`date +"%Y%m%d_%H%M%S"`
# NO_JOB_LOGGING="false"

ScriptName=`basename $0`
# Job=`basename $0 .sh`"_whatever_I_want" # Add _whatever_I_want after basename
Job=`basename $0 .sh`
JobClass=`basename $0 .sh`

colblk='\033[0;30m' # Black - Regular
colred='\033[0;31m' # Red
colgrn='\033[0;32m' # Green
colylw='\033[0;33m' # Yellow
colpur='\033[0;35m' # Purple
colwht='\033[0;97m' # White
colrst='\033[0m'    # Text Reset

verbosity=4

### verbosity levels
silent_lvl=0
crt_lvl=1
err_lvl=2
wrn_lvl=3
ntf_lvl=4
inf_lvl=5
dbg_lvl=6

## esilent prints output even in silent mode
function esilent () { verb_lvl=$silent_lvl elog "$@" ;}
function enotify () { verb_lvl=$ntf_lvl elog "$@" ;}
function eok ()    { verb_lvl=$ntf_lvl elog "SUCCESS - $@" ;}
function ewarn ()  { verb_lvl=$wrn_lvl elog "${colylw}WARNING${colrst} - $@" ;}
function einfo ()  { verb_lvl=$inf_lvl elog "${colwht}INFO${colrst} ---- $@" ;}
function edebug () { verb_lvl=$dbg_lvl elog "${colgrn}DEBUG${colrst} --- $@" ;}
function eerror () { verb_lvl=$err_lvl elog "${colred}ERROR${colrst} --- $@" ;}
function ecrit ()  { verb_lvl=$crt_lvl elog "${colpur}FATAL${colrst} --- $@" ;}
function edumpvar () { for var in $@ ; do edebug "$var=${!var}" ; done }
function elog() {
        if [ $verbosity -ge $verb_lvl ]; then
                datestring=`date +"%Y-%m-%d %H:%M:%S"`
                echo -e "$datestring - $@"
        fi
}

function Log_Open() {
        if [ $NO_JOB_LOGGING ] ; then
                einfo "Not logging to a logfile because -Z option specified." #(*)
        else
                [[ -d $LOGDIR/$JobClass ]] || mkdir -p $LOGDIR/$JobClass
                Pipe=${LOGDIR}/$JobClass/${Job}_${DATETIME}.pipe
                mkfifo -m 700 $Pipe
                LOGFILE=${LOGDIR}/$JobClass/${Job}_${DATETIME}.log
                exec 3>&1
                tee ${LOGFILE} <$Pipe >&3 &
                teepid=$!
                exec 1>$Pipe
                PIPE_OPENED=1
                enotify Logging to $LOGFILE  # (*)
                [ $SUDO_USER ] && enotify "Sudo user: $SUDO_USER" #(*)
        fi
}

function Log_Close() {
        if [ ${PIPE_OPENED} ] ; then
                exec 1<&3
                sleep 0.2
                ps --pid $teepid >/dev/null
                if [ $? -eq 0 ] ; then
                        # a wait $teepid whould be better but some
                        # commands leave file descriptors open
                        sleep 1
                        kill  $teepid
                fi
                rm $Pipe
                unset PIPE_OPENED
        fi
}


OPTIND=1
while getopts ":sVGZ" opt ; do
# shellcheck disable=SC2220
        case $opt in
        s)
                verbosity=$silent_lvl
                edebug "-s specified: Silent mode"
                ;;
        V)
                verbosity=$inf_lvl
                edebug "-V specified: Verbose mode"
                ;;
        G)
                verbosity=$dbg_lvl
                edebug "-G specified: Debug mode"
                ;;
        Z)
                NO_JOB_LOGGING="true"
                ;;
        esac
done

# Options for logging
ewarn "this is a warning"
eerror "this is an error"
einfo "this is an information"
edebug "debugging"
ecrit "CRITICAL MESSAGE!"
edumpvar HOSTNAME

## Check for system updates.

sudo apt update

## Perform full upgrade.

sudo apt full-upgrade -y

## Install Unbound package.

sudo apt install unbound sqlite3 resolvconf -y

## Download and install root.hints file for unbound.

wget https://www.internic.net/domain/named.root -qO- | sudo tee /var/lib/unbound/root.hints 

# Configure resolvconf head file for cloudflare dns.
sudo cat <<EOF >/etc/resolvconf/resolv.conf.d/head
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF

## Restart resolvconf service to update sources for pihole lists (This is only to fix the DNS resolution unavailable error).
sudo resolvconf --enable-updates
sudo resolvconf -u

## Complete unbound config including tweaks.

sudo cp pi-hole.conf /etc/unbound/unbound.conf.d/pi-hole.conf

## Configure Cron to update Root Hints and Whitelist files.

sudo cp crontab /etc/crontab

## Configure NTP for DNSSec

sudo cat <<EOF >/etc/systemd/timesyncd.conf
FallbackNTP=194.58.204.20 pool.ntp.org
EOF

## Disable unbound-resolvconf.
sudo systemctl disable unbound-resolvconf.service
sudo systemctl stop unbound-resolvconf.service

## Restart unbound after config changes.

sudo systemctl restart unbound

## Install Pihole (OS Check flag for ubuntu 22.04).

sudo curl -sSL https://install.pi-hole.net | sudo PIHOLE_SKIP_OS_CHECK=true bash

## Modifier to disable cache and DNS sec. Switches DNS to Unbound instance.

sudo cp 01-pihole.conf /etc/dnsmasq.d/01-pihole.conf

## Config to ensure settings remain through updates.

sudo cp setupVars.conf /etc/pihole/setupVars.conf

## Tweaks for Pihole-FTL.

sudo cp pihole-FTL.conf /etc/pihole/pihole-FTL.conf

## Add more lists to pihole.

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

## Update gravity db.

sudo pihole -g

## Configure dnsmasq packet size cap.

sudo cat <<EOF >/etc/dnsmasq.d/99-edns.conf
edns-packet-max=1232
EOF

## Switch to opt folder to download whitelist scripts.

cd /opt/

## Download whitelist scrips for pihole.

sudo git clone https://github.com/anudeepND/whitelist.git 

## Move to Whitelist Directory.

cd /opt/whitelist/scripts

## Run Whitelist script for first time. (Cron will run this on schedule).

sudo ./whitelist.py

## Password Reminder.

echo "Remember to run sudo pihole -a -p to change your password and reboot the system to finish."
