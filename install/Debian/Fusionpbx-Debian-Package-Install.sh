#!/bin/bash
#Date Aug 26 2014 15:00 CST
################################################################################
# The MIT License (MIT)
#
# Copyright (c) <2013> <r.neese@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
################################################################################
cat  <<  DELIM
            This is a one time install script. (NOT MENT FOR LAMP INSTALLS)
            This script is ment to be run on a fresh install of debian 7 (wheezy).
            It is not intended to be run multi times
            If it fails for any reason please report to r.neese@gmail.com. 
            Please include any screen output you can to show where it fails.
DELIM
################################################################################
#checks to see if installing on openvz server
if [[ -f /proc/vz ]]; then
cat << DELIM
      Note: "
            Those of you running this script on openvz. You must run it as root and 
            bash  Fusionpbx-Debian-Pkg-Install-New.sh or it fails the networking check.
            Please take the time to refer to this document if you have install issues 
            on openvz
            http://openvz.org/Virtual_Ethernet_device and make sure to setup a eth0 .
DELIM
exit
fi
################################################################################
case $(uname -m) in armv7l)
cat << DELIM
    Note:
        It is suggested you only use sqlite and or postgresql client for best preformance on 
        armhf when using a sd or emmc or nand.
        For those arm units supporting sata and usb3 harddrives you can opt for Postgrsql if 
        you wish. Currently only Postgresql 9.1 is supported in the armhf pkgs. I have not 
        foud a repo with 9.3 pkgs. I will update the script when I do.
DELIM
esac
################################################################################

#<------Start Edit HERE--------->

#Network Interface selection
#Default = eth0 
net_iface=eth0

#Use for configuring a odroid
odroid_boards="n"

#Required
#Stable/release=1.4/master=1.5 aka git head
# Default is stable (currently there is only one working repo for freeswitch)
freeswitch_repo="stable"

#Fusionpbx repo (release = 3.6.0 / devel = 3.5) 
fusionpbx_repo="release"

#Set how long to keep freeswitch/fusionpbx log files 1 to 30 days (Default:5)
keep_logs=5

#----Optional Apps/Modules----

adminer="n" # : integrated for an administrator in the superadmin group to enable easy database access
backup="n" # : pbx backup module. backup sqlite db / configs/ logs
call_broadcast="n" # : Create a recording and select one or more groups to have the system call and play the recording
call_center="n" # : display queue status, agent status, tier status for call centers using mod_callcenter call queues
call_flows="n" # : Typically used with day night mode. To direct calls between two destinations. 
conference_centers="n" # : tools for multi room confrences and room contol
conference="n" # : tools for single room confrences and room contol
content="n" # : Advanced-Content Manager
edit="n" # : multi tools for editing (templates/xmlfiles/configfiles/scripts) files
exec="n" # : comman shells pages for executing (php/shells) commands
fax="n" # : fusionpbx send/recieve faxes service
fifo="n" # : first in first out call queues system
hot_desk="n" # : allows users to login and recieve calls on any office phone
schemas="n" # :
services="n" # : allows interaction with the processes running on your server
sipml5="n" # : php base softphone 
sql_query="n" # : allows you to interactively submit SQL queries to the database used in FusionPBX
traffic_graph="n" # : php graph for monitoing the network interface traffic
xmpp="n" # : Configure XMPP to work with Google talk or other jabber servers
aastra="n" # : phone provisioning tool &  templates for aastra phones
cisco="n" # : phone provisioning tool & templates for cisco phones
grandstream="n" # : phone provisioning tool & templates for grandstream phones
linksys="n" # : phone provisioning tool & templates for linksys phones
panasonic="n" # : phone provisioning tool & templates for panasonic phones
polycom="n" # : phone provisioning tool & templates for polycom phones
snom="n" # : provisioning tool & templates for snom phones
yealink="n" # : phone provisioning tool & templates for yealink phones
verto="n" # (x86/amd64 Only) (future option on arm)
minimized_theme="n" # : minimal theme for fusionpbx
all="n" #: Install all extra modules for fusionpbx and related freeswitch deps

#------Postgresql start-------
#Optional (Not Required)
# Please Select Server or Client not both.
# Used for connecting to remote postgresql database servers
# Install postgresql Client 9.3 for connection to remote postgresql servers (y/n)
postgresql_client="n"

# Install postgresql server 9.3 (y/n) (client included)(Local Machine)
# Notice:
# You should not use postgresql server on a nand/emmc/sd. It cuts the performance
# life in half due to all the needed reads and writes. This cuts the life of
# your pbx emmc/sd in half.
postgresql_server="n"

# Set Postgresql Server Admin username ( Lower case only )
pgsql_admin=

# Set Postgresql Server Admin password
pgsql_admin_passwd=

# Set Database Name used for fusionpbx in the postgresql server
# (Default: fusionpbx)
db_name=fusionpbx

# Set FusionPBX database admin name.(used by fusionpbx to access
# the database table in the postgresql server.
# (Default: fusionpbx)
db_user_name=fusionpbx

# Set FusionPBX database admin password .(used by fusionpbx to access
# the database table in the postgresql server).
# Please set a ver secure passwd
db_user_passwd=

#-------Postgresql-End--------------

#Extra Option's
#Install openvpn scripts
install_openvpn="n"

#Install Ajenti Optional Admin Portal
install_ajenti="n"
 
#-------- Edit only if necessary---------
#Custom Dir Layout
fs_conf_dir="/etc/freeswitch"
fs_dflt_conf_dir="/usr/share/freeswitch/conf"
fs_db_dir="/var/lib/freeswitch/db"
fs_log_dir="/var/log/freeswitch"
#fs_mod_dir="/usr/lib/freeswitch/mod" (not currently used)
fs_recordings_dir="/var/lib/freeswitch/recordings"
fs_run_dir="/var/run/freeswitch"
fs_scripts_dir="/var/lib/fusionpbx/scripts"
fs_storage_dir="/var/lib/freeswitch/storage"
#fs_temp_dir="/tmp"
fs_usr=freeswitch
fs_grp=$fs_usr

#<------Stop Edit Here-------->

################################################################################
# Hard Set Varitables (Do Not EDIT)
#Nginx default www dir
WWW_PATH="/usr/share/nginx/www" #debian nginx default dir
#set Web User Interface Dir Name
wui_name="fusionpbx"
#Php ini config file
php_ini="/etc/php5/fpm/php.ini"
#################################################################################
#Start installation

#Testing for internet connection. Pulled from and modified
#http://www.linuxscrew.com/2009/04/02/tiny-bash-scripts-check-internet-connection-availability/
#test internet connection..
echo "This Script Currently Requires a internet connection "
wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google &> /dev/null

if [ ! -s /tmp/index.google ];then
	echo "No Internet connection. Please check ethernet cable"
	/bin/rm /tmp/index.google
	exit 1
else
	echo "Found the Internet ... continuing!"
	/bin/rm /tmp/index.google
fi

# OS ENVIRONMENT CHECKS
#check to confirm running as root
#
# First, we need to be root...
#

if [ "$(id -u)" -ne "0" ]; then
  sudo -p "$(basename "$0") must be run as root, please enter your sudo password : " "$0" "$@"
  exit 0
fi

echo "You're root.... continuing!"

#removes the cd img from the /etc/apt/sources.list file (not needed after base install)
sed -i '/cdrom:/d' /etc/apt/sources.list
#sed -i '2,4d' /etc/apt/sources.list

#if lsb_release is not installed it installs it
if [ ! -s /usr/bin/lsb_release ]; then
	apt-get update && apt-get -y install lsb-release
fi

# Os/Distro Check
lsb_release -c |grep -i wheezy &> /dev/null 2>&1
if [ $? -eq 0 ]; then
		/bin/echo "Good, you are running Debian 7 codename: wheezy"
		/bin/echo
else
		lsb_release -c |grep -i jessie > /dev/null
		if [ $? -eq 0 ]; then
                /bin/echo "OK you are running Debian 8 CodeName: Jessie. This script is known to work"
		/bin/echo
                CONTINUE=YES
        fi
        lsb_release -c |grep -i saucy > /dev/null
        if [ $? -eq 0 ]; then
                /bin/echo "OK you're running Ubuntu 13.10 [saucy].  This script is a work in progress."
                /bin/echo "   It is not recommended that you try it at this time."
                /bin/echo 
                CONTINUE=YES
        else
                /bin/echo "This script was written for Debian 7 codename wheezy"
                /bin/echo
                /bin/echo "Your OS appears to be:"
                lsb_release -a
                read -p "Do you wish to continue y/n? " CONTINUE

                case "$CONTINUE" in
                [yY]*)
                        /bin/echo 'Ok, this does not always work..,'
                        /bin/echo '  but well give it a go.'
                ;;

                *)
                        /bin/echo 'Exiting the install.'
                        exit 1
                ;;
                esac
        fi
fi

apt-get update && apt-get -y upgrade
apt-get -y install acpi-support-base usbmount usbutils

#freeswitch repo for x86 x86-64 bit pkgs
case $(uname -m) in x86_64|i[4-6]86)
# install curl to fetch repo key
echo ' installing curl '
apt-get update && apt-get -y install curl

#adding in freeswitch reop to /etc/apt/sources.list.d/freeswitch.lists

if [[ $freeswitch_repo == "stable" ]]; then
echo ' installing stable repo '
/bin/cat > "/etc/apt/sources.list.d/freeswitch.list" <<DELIM
deb http://files.freeswitch.org/repo/deb/debian/ wheezy main
DELIM

elif [[ $freeswitch_repo == "beta" ]]; then
echo 'installing beta repo'
/bin/cat > "/etc/apt/sources.list.d/freeswitch.list" <<DELIM
deb http://files.freeswitch.org/repo/deb-beta/debian/ wheezy main
DELIM

elif [[ $freeswitch_repo == "master" ]]; then
echo 'install master repo'
/bin/cat > "/etc/apt/sources.list.d/freeswitch.list" <<DELIM
deb http://files.freeswitch.org/repo/deb-master/debian/ wheezy main
DELIM
fi

#adding key for freeswitch repo
echo 'fetcing repo key'
curl http://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add -
for i in update upgrade ;do apt-get -y "${i}" ; done
esac

#adding FusionPBX repo
if [[ $fusionpbx_repo == "release" ]]; then
echo 'installing fusionpbx release repo'
/bin/cat > "/etc/apt/sources.list.d/fusionpbx.list" <<DELIM
deb http://repo.fusionpbx.com/deb/debian/ wheezy main
DELIM

elif [[ $fusionpbx_repo == "devel" ]]; then
echo 'installing fusionpbx devel repo'
/bin/cat > "/etc/apt/sources.list.d/fusionpbx.list" <<DELIM
deb http://repo.fusionpbx.com/deb-dev/debian/ wheezy main
DELIM
fi

#postgresql 9.3 repo for x86 x86-64 bit pkgs
case $(uname -m) in x86_64|i[4-6]86)
#add in pgsql 9.3
cat > "/etc/apt/sources.list.d/pgsql-pgdg.list" << DELIM
deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main
DELIM
#add pgsql repo key
wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
esac

apt-get update
apt-get -y install ntp
service ntp restart
apt-get upgrade

#install Freeswitch Deps
apt-get -y install curl unixodbc uuid memcached libtiff5 libtiff-tools 

# install freeswitch
apt-get -y install --force-yes freeswitch freeswitch-init freeswitch-lang-en freeswitch-meta-codecs freeswitch-mod-commands freeswitch-mod-curl \
		freeswitch-mod-db freeswitch-mod-distributor freeswitch-mod-dptools freeswitch-mod-enum freeswitch-mod-esf freeswitch-mod-esl \
		freeswitch-mod-expr freeswitch-mod-fsv freeswitch-mod-hash freeswitch-mod-memcache freeswitch-mod-portaudio freeswitch-mod-portaudio-stream \
		freeswitch-mod-random freeswitch-mod-spandsp freeswitch-mod-spy freeswitch-mod-translate freeswitch-mod-valet-parking freeswitch-mod-flite \
		freeswitch-mod-pocketsphinx freeswitch-mod-tts-commandline freeswitch-mod-dialplan-xml freeswitch-mod-loopback freeswitch-mod-sofia \
		freeswitch-mod-event-multicast freeswitch-mod-event-socket freeswitch-mod-event-test freeswitch-mod-local-stream freeswitch-mod-native-file \
		freeswitch-mod-sndfile freeswitch-mod-tone-stream freeswitch-mod-lua freeswitch-mod-console freeswitch-mod-logfile freeswitch-mod-syslog \
		freeswitch-mod-say-en freeswitch-mod-posix-timer freeswitch-mod-timerfd freeswitch-mod-v8 freeswitch-mod-xml-cdr freeswitch-mod-xml-curl \
		freeswitch-mod-xml-rpc freeswitch-sounds freeswitch-music freeswitch-conf-vanilla

case $(uname -m) in x86_64|i[4-6]86)
apt-get -y install freeswitch-mod-shout
esac

case $(uname -m) in armv7l)
apt-get -y install freeswitch-mod-vlc
esac

#make the conf dir 
mkdir -p "$fs_conf_dir"

#cp the default configugs into place.
cp -rp "$fs_dflt_conf_dir"/vanilla/* "$fs_conf_dir"
#remove un needed default extension xml files
rm "$fs_conf_dir"/directory/default/*
#rm un used default dialplan xml files
rm "$fs_conf_dir"/dialplan/default/*

#fix ownership of files for freeswitch and fusion to have access with no conflicts
chown -R freeswitch:freeswitch "$fs_conf_dir"

#fix permissions for "$fs_conf_dir" so www-data can write to it
find "$fs_conf_dir" -type f -exec chmod 664 {} +
find "$fs_conf_dir" -type d -exec chmod 775 {} +
#fix permissions for "$fs_storage_dir" so www-data can write to it
find "/var/lib/freeswitch/storage" -type f -exec chmod 664 {} +
find "/var/lib/freeswitch/storage" -type d -exec chmod 775 {} +

#fix permissions on the freeswitch xml_cdr dir so fusionpbx can read from it
find "$fs_log_dir"/xml_cdr -type d -exec chmod 775 {} +

cat > "/etc/default/freeswitch" << DELIM
CONFDIR=$fs_conf_dir
fs_usr=
fs_grp=$fs_usr
fs_conf_dir=
fs_db_dir=
fs_log_dir=
fs_scripts_dir=
fs_run_dir=
fs_storage_dir=
fs_recordings_dir=
fs_options= -nc
DAEMON_ARGS="-u $fs_usr -g $fs_grp -rp -conf $fs_conf_dir -db $fs_db_dir -log $fs_log_dir -scripts $fs_scripts_dir -run $fs_run_dir -storage $fs_storage_dir -recordings $fs_recordings_dir fs_options"
DELIM

service freeswitch restart

#Start of FusionPBX / nginx / php5 install
#Install and configure  PHP + Nginx + sqlite3 for use with the fusionpbx gui.

apt-get -y install sqlite3 ssl-cert nginx php5-cli php5-common php-apc php5-gd php-db \
				php5-fpm php5-memcache php5-odbc php-pear php5-sqlite
				
# Changing file upload size from 2M to 15M
/bin/sed -i $php_ini -e 's#"upload_max_filesize = 2M"#"upload_max_filesize = 15M"#'

#Nginx config Copied from Debian nginx pkg (nginx on debian wheezy uses sockets by default not ports)
cat > "/etc/nginx/sites-available/fusionpbx"  << DELIM
server{
        listen 127.0.0.1:80;
        server_name 127.0.0.1;
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        client_max_body_size 10M;
        client_body_buffer_size 128k;

        location / {
                root $WWW_PATH/$wui_name;
                index index.php;
        }

        location ~ \.php$ {
                fastcgi_pass unix:/var/run/php5-fpm.sock;
                #fastcgi_pass 127.0.0.1:9000;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param   SCRIPT_FILENAME $WWW_PATH/$wui_name\$fastcgi_script_name;
        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
                        deny all;
        }
        location ~ .htpassword {
                        deny all;
        }
        location ~^.+.(db)$ {
                        deny all;
        }
}

server{
        listen 80;
        listen [::]:80 default_server ipv6only=on;
        server_name $wui_name;
        if (\$uri !~* ^.*provision.*$) {
                rewrite ^(.*) https://\$host\$1 permanent;
                break;
        }

		#grandstream
        rewrite "^.*/provision/cfg([A-Fa-f0-9]{12})(\.(xml|cfg))?$" /app/provision/?mac=$1;

		#aastra
		#rewrite "^.*/provision/([A-Fa-f0-9]{12})(\.(cfg))?$" /app/provision/?mac=$1 last;

		#yealink common
		rewrite "^.*/provision/(y[0-9]{12})(\.cfg)?$" /app/provision/index.php?file=$1$2;

		#yealink mac
		rewrite "^.*/([A-Fa-f0-9]{12})(\.(xml|cfg))?$" /app/provision/index.php?mac=\$1 last;
	
		if (\$uri !~* ^.*provision.*$) {
			rewrite ^(.*) https://\$host\$1 permanent;
			break;
		}	
		
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/.error.log;

        client_max_body_size 15M;
        client_body_buffer_size 128k;

        location / {
          root $WWW_PATH/$wui_name;
          index index.php;
        }

        location ~ \.php$ {
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param   SCRIPT_FILENAME $WWW_PATH/$wui_name\$fastcgi_script_name;
        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
                deny all;
        }
        location ~ .htpassword {
                deny all;
        }
        location ~^.+.(db)$ {
                deny all;
        }
}

server{
        listen 443;
        listen [::]:443 default_server ipv6only=on;
        server_name $wui_name;
        ssl                     on;
        ssl_certificate         /etc/ssl/certs/ssl-cert-snakeoil.pem;
        ssl_certificate_key     /etc/ssl/private/ssl-cert-snakeoil.key;
        ssl_protocols           SSLv3 TLSv1;
        ssl_ciphers     HIGH:!ADH:!MD5;

		#grandstream
        rewrite "^.*/provision/cfg([A-Fa-f0-9]{12})(\.(xml|cfg))?$" /app/provision/?mac=$1;

		#aastra
		#rewrite "^.*/provision/([A-Fa-f0-9]{12})(\.(cfg))?$" /app/provision/?mac=$1 last;

		#yealink common
		rewrite "^.*/provision/(y[0-9]{12})(\.cfg)?$" /app/provision/index.php?file=$1$2;

		#yealink mac
		rewrite "^.*/provision/([A-Fa-f0-9]{12})(\.(xml|cfg))?$" /app/provision/index.php?mac=$1 last;

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/.error.log;

        client_max_body_size 15M;
        client_body_buffer_size 128k;

        location / {
          root $WWW_PATH/$wui_name;
          index index.php;
        }

        location ~ \.php$ {
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param   SCRIPT_FILENAME $WWW_PATH/$wui_name\$fastcgi_script_name;
        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
                deny all;
        }
        location ~ .htpassword {
                deny all;
        }
        location ~^.+.(db)$ {
                deny all;
        }
}
DELIM

cat > "/etc/nginx/nginx.conf"  << DELIM
user www-data;
worker_processes 2;
pid /var/run/nginx.pid;

events {
	worker_connections 768;
	multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 75;
	keepalive_requests 10000;
	types_hash_max_size 2048;
	# server_tokens off;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	open_file_cache max=1000 inactive=20s;
	open_file_cache_valid 30s;
	open_file_cache_min_uses 2;
	open_file_cache_errors off;
	
	fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=microcache:10m max_size=1000m inactive=60m;
	
	##
	# Logging Settings
	##

	#access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##

	gzip on;
	gzip_static on;
	gzip_disable "msie6";

	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

	##
	# nginx-naxsi config
	##
	# Uncomment it if you installed nginx-naxsi
	##

	#include /etc/nginx/naxsi_core.rules;

	##
	# nginx-passenger config
	##
	# Uncomment it if you installed nginx-passenger
	##
	
	#passenger_root /usr;
	#passenger_ruby /usr/bin/ruby;

	##
	# Virtual Host Configs
	##

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}

DELIM

# linking fusionpbx nginx config from avaible to enabled sites
ln -s /etc/nginx/sites-available/"$wui_name" /etc/nginx/sites-enabled/"$wui_name"

#disable default site
rm -rf /etc/nginx/sites-enabled/default

#Restarting Nginx and PHP FPM
for i in nginx php5-fpm ;do service "${i}" restart > /dev/null 2>&1 ; done

#Adding users to needed groups
adduser www-data freeswitch
adduser freeswitch www-data

# Install FusionPBX Web User Interface 
apt-get -y --force-yes install fusionpbx-core fusionpbx-app-calls fusionpbx-app-calls-active fusionpbx-app-call-block \
		fusionpbx-app-contacts fusionpbx-app-destinations fusionpbx-app-dialplan fusionpbx-app-dialplan-inbound \
		fusionpbx-app-dialplan-outbound fusionpbx-app-extensions fusionpbx-app-follow-me fusionpbx-app-gateways \
		fusionpbx-app-ivr-menu fusionpbx-app-login fusionpbx-app-log-viewer fusionpbx-app-modules fusionpbx-app-music-on-hold \
		fusionpbx-app-recordings fusionpbx-app-registrations fusionpbx-app-ring-groups fusionpbx-app-settings \
		fusionpbx-app-sip-profiles fusionpbx-app-sip-status fusionpbx-app-system fusionpbx-app-time-conditions \
		fusionpbx-sounds fusionpbx-app-xml-cdr fusionpbx-app-vars fusionpbx-app-voicemails fusionpbx-app-voicemail-greetings \
		fusionpbx-conf fusionpbx-scripts fusionpbx-sqldb fusionpbx-theme-enhanced

#Optional APP PKGS
if [[ $adminer == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-adminer
fi
if [[ $backup == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-backup
fi
if [[ $call_broadcast == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-call-broadcast
fi
if [[ $call_center == "y" ]]; then
apt-get -y --force-yes install freeswitch-mod-callcenter fusionpbx-app-call-center fusionpbx-app-call-center-active
fi
if [[ $call_flows == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-call-flows
fi
if [[ $conference_center == "y" ]]; then
apt-get -y --force-yes install freeswitch-mod-conference fusionpbx-app-conference-centers fusionpbx-app-conferences-active fusionpbx-app-meetings
fi
if [[ $conference == "y" ]]; then
apt-get -y --force-yes install freeswitch-mod-conference fusionpbx-app-conferences fusionpbx-app-conferences-active fusionpbx-app-meetings 
fi
if [[ $content == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-content 
fi
if [[ $edit == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-edit
fi
if [[ $exec == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-exec
fi
if [[ $fax == "y" ]]; then
apt-get -y --force-yes install ghostscript libreoffice-common fusionpbx-app-fax
fi
if [[ $fifo == "y" ]]; then
apt-get -y --force-yes install freeswitch-mod-fifo fusionpbx-app-fifo fusionpbx-app-fifo-list
fi
if [[ $hot_desking == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-hot-desking
fi
if [[ $schemas == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-schemas
fi
if [[ $services == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-services
fi
if [[ $rtmp == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-sipml5 freeswitch-mod-rtmp
fi
if [[ $sql_query == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-sql-query
fi
if [[ $traffic_graph == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-traffic-graph
fi
if [[ $xmpp == "y" ]]; then
apt-get -y --force-yes install freeswitch-mod-dingaling fusionpbx-app-xmpp;
fi
if [[ $aastra == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-devices fusionpbx-app-provision fusionpbx-provisioning-template-aastra  && mkdir -p /etc/fusionpbx/resources/templates/provision && cp -rp /usr/share/examples/fusionpbx/resources/templates/provision/aastra /etc/fusionpbx/resources/templates/provision/
fi
if [[ $cisco == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-devices fusionpbx-app-provision fusionpbx-provisioning-template-cisco && mkdir -p /etc/fusionpbx/resources/templates/provision && cp -rp /usr/share/examples/fusionpbx/resources/templates/provision/cisco /etc/fusionpbx/resources/templates/provision/
fi
if [[ $grandstream == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-devices fusionpbx-app-provision fusionpbx-provisioning-template-grandstream && mkdir -p /etc/fusionpbx/resources/templates/provision && cp -rp /usr/share/examples/fusionpbx/resources/templates/provision/grandstream /etc/fusionpbx/resources/templates/provision/
fi
if [[ $linksys == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-devices fusionpbx-app-provision fusionpbx-provisioning-template-linksys  && mkdir -p /etc/fusionpbx/resources/templates/provision && cp -rp /usr/share/examples/fusionpbx/resources/templates/provision/linksys /etc/fusionpbx/resources/templates/provision/
fi
if [[ $panasonic == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-devices fusionpbx-app-provision fusionpbx-provisioning-template-panasonic  && mkdir -p /etc/fusionpbx/resources/templates/provision && cp -rp /usr/share/examples/fusionpbx/resources/templates/provision/panasonic /etc/fusionpbx/resources/templates/provision/
fi
if [[ $polycom == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-devices fusionpbx-app-provision fusionpbx-provisioning-template-polycom && mkdir -p /etc/fusionpbx/resources/templates/provision && cp -rp /usr/share/examples/fusionpbx/resources/templates/provision/polycom /etc/fusionpbx/resources/templates/provision/
fi
if [[ $snom == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-devices fusionpbx-app-provision fusionpbx-provisioning-template-snom && mkdir -p /etc/fusionpbx/resources/templates/provision && cp -rp /usr/share/examples/fusionpbx/resources/templates/provision/snom /etc/fusionpbx/resources/templates/provision/
fi
if [[ $yealink == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-devices fusionpbx-app-provision fusionpbx-provisioning-template-yealink && mkdir -p /etc/fusionpbx/resources/templates/provision && cp -rp /usr/share/examples/fusionpbx/resources/templates/provision/yealink /etc/fusionpbx/resources/templates/provision/
fi 
if [[ $verto == "y" ]]; then
apt-get -y --force-yes install freeswitch-mod-verto
fi
if [[ $minimized == "y" ]]; then
apt-get -y --force-yes install freeswitch-theme-minimized
fi
if [[ $all == "y" ]]; then
apt-get -y --force-yes install fusionpbx-app-adminer fusionpbx-app-backup fusionpbx-app-call-broadcast freeswitch-mod-callcenter fusionpbx-app-call-center fusionpbx-app-call-center-active fusionpbx-app-call-flows freeswitch-mod-conference fusionpbx-app-conference-centers \
  				fusionpbx-app-conferences-active fusionpbx-app-meetings fusionpbx-app-conferences fusionpbx-app-content fusionpbx-app-edit fusionpbx-app-exec freeswitch-mod-fifo fusionpbx-app-fifo fusionpbx-app-fifo-list fusionpbx-app-hot-desking fusionpbx-app-schemas \
  				fusionpbx-app-services fusionpbx-app-sipml5 freeswitch-mod-rtmp fusionpbx-app-sql-query fusionpbx-app-traffic-graph freeswitch-mod-dingaling fusionpbx-app-xmpp fusionpbx-app-devices fusionpbx-app-provision fusionpbx-provisioning-template-aastra \
  				fusionpbx-provisioning-template-cisco fusionpbx-provisioning-template-grandstream fusionpbx-provisioning-template-linksys fusionpbx-provisioning-template-panasonic fusionpbx-app-provision fusionpbx-provisioning-template-polycom fusionpbx-app-provision \
  				fusionpbx-provisioning-template-snom fusionpbx-provisioning-template-yealink fusionpbx-theme-minimized && mkdir -p /etc/fusionpbx/resources/templates/provision && cp -rp /usr/share/examples/fusionpbx/resources/templates/provision/* /etc/fusionpbx/resources/templates/provision/
fi

#set permissions
chmod 775 /etc/fusionpbx
chmod 775 /var/lib/fusionpbx
chmod 777 /var/lib/fusionpbx/db

mkdir -p /var/lib/fusionpbx/scripts
chown -R freeswitch:freeswitch /var/lib/fusionpbx/scripts
find "$fs_scripts_dir" -type d -exec chmod 775 {} +
find "$fs_scripts_dir" -type f -exec chmod 664 {} +

#fix permissions for "freeswitch sounds dir " so www-data can write to it
find /usr/share/freeswitch/sounds -type f -exec chmod 664 {} +
find /usr/share/freeswitch/sounds -type d -exec chmod 775 {} +

#create xml_cdr dir and chown it properly if the module is installed
mkdir -p "$fs_log_dir"/xml_cdr

#chown the xml_cdr dir
chown freeswitch:freeswitch "$fs_log_dir"/xml_cdr

#fix permissions on the freeswitch xml_cdr dir so fusionpbx can read from it
chmod 775 "$fs_log_dir"/xml_cdr

for i in freeswitch nginx php5-fpm ;do service "${i}" restart >/dev/null 2>&1 ; done

cat > "/etc/default/freeswitch" << DELIM
CONFDIR=$fs_conf_dir
fs_usr=
fs_grp=$fs_usr
fs_conf_dir=
fs_db_dir=
fs_log_dir=
fs_scripts_dir=
fs_run_dir=
fs_storage_dir=
fs_recordings_dir=
fs_options= -nc
DAEMON_ARGS="-u $fs_usr -g $fs_grp -rp -conf $fs_conf_dir -db $fs_db_dir -log $fs_log_dir -scripts $fs_scripts_dir -run $fs_run_dir -storage $fs_storage_dir -recordings $fs_recordings_dir fs_options"
DELIM

service freeswitch restart

# SEE http://wiki.freeswitch.org/wiki/Fail2ban
#Fail2ban
for i in fail2ban monit ;do apt-get -y install "${i}" ; done

#Taken From http://wiki.fusionpbx.com/index.php?title=Monit and edited to work with debian pkgs.
#Adding Monit to keep freeswitch running.
/bin/cat > "/etc/monit/conf.d/freeswitch"  <<DELIM
set daemon 60
set logfile syslog facility log_daemon

check process freeswitch with pidfile /var/run/freeswitch/freeswitch.pid
restart program = "/etc/init.d/freeswitch restart"
start program = "/etc/init.d/freeswitch start"
stop program = "/etc/init.d/freeswitch stop"

DELIM

#Setting up Fail2ban freeswitch config files.
/bin/cat > "/etc/fail2ban/filter.d/freeswitch.conf" <<DELIM

# Fail2Ban configuration file

[Definition]

failregex = \[WARNING\] sofia_reg.c:\d+ SIP auth failure \(REGISTER\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>
            \[WARNING\] sofia_reg.c:\d+ SIP auth failure \(INVITE\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>

ignoreregex =
DELIM

/bin/cat > /etc/fail2ban/filter.d/freeswitch-dos.conf  <<DELIM

# Fail2Ban DOS configuration file

[Definition]

failregex = \[WARNING\] sofia_reg.c:\d+ SIP auth challenge \(REGISTER\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>

ignoreregex =
DELIM

/bin/cat >> "/etc/fail2ban/jail.local" <<DELIM
[freeswitch-tcp]
enabled  = true
port     = 5060,5061,5080,5081
protocol = tcp
filter   = freeswitch
logpath  = /var/log/freeswitch/freeswitch.log
action   = iptables-allports[name=freeswitch-tcp, protocol=all]
maxretry = 5
findtime = 600
bantime  = 600

[freeswitch-udp]
enabled  = true
port     = 5060,5061,5080,5081
protocol = udp
filter   = freeswitch
logpath  = /var/log/freeswitch/freeswitch.log
action   = iptables-allports[name=freeswitch-udp, protocol=all]
maxretry = 5
findtime = 600
bantime  = 600

[freeswitch-dos]
enabled = true
port = 5060,5061,5080,5081
protocol = udp
filter = freeswitch-dos
logpath = /var/log/freeswitch/freeswitch.log
action = iptables-allports[name=freeswitch-dos, protocol=all]
maxretry = 50
findtime = 30
bantime  = 6000
DELIM

#Pulled From
#http://wiki.fusionpbx.com/index.php?title=Fail2Ban
# Adding fusionpbx to fail2ban
cat > "/etc/fail2ban/filter.d/fusionpbx.conf"  <<DELIM
# Fail2Ban configuration file
#
[Definition]
failregex = .* fusionpbx: \[<HOST>\] authentication failed for
          = .* fusionpbx: \[<HOST>\] provision attempt bad password for

ignoreregex =
DELIM

/bin/cat >> /etc/fail2ban/jail.local  <<DELIM

[fusionpbx]
enabled  = true
port     = 80,443
protocol = tcp
filter   = fusionpbx
logpath  = /var/log/auth.log
action   = iptables-allports[name=fusionpbx, protocol=all]

maxretry = 5
findtime = 600
bantime  = 600
DELIM

cat > "/etc/fail2ban/filter.d/fusionpbx-inbound.conf" <<DELIM
# Fail2Ban configuration file
# inbound route - 404 not found

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>[\w\-.^_]+)
# Values:  TEXT
#
#failregex = [hostname] FusionPBX: \[<HOST>\] authentication failed
#[hostname] variable doesn't seem to work in every case. Do this instead:
failregex = 404 not found <HOST>

#EXECUTE sofia/external/9999421150@cgrates.directvoip.co.uk log([inbound routes] 404 not found 82.68.115.62)

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =

DELIM

/bin/cat >> /etc/fail2ban/jail.local  <<DELIM

[fusionpbx-inbound]
enabled  = true
port 	= 5080
protocol = udp
filter   = fusionpbx-inbound
logpath  = /var/log/freeswitch/freeswitch.log
action   = iptables-allports[name=fusionpbx-inbound, protocol=all]
#      	sendmail-whois[name=fusionpbx-inbound, dest=root, sender=fail2ban@example.org] #no smtp server installed
maxretry = 5
findtime = 300
bantime  = 3600
DELIM

#restarting fail2ban
service fail2ban restart

#Turning off RepeatedMsgReduction in /etc/rsyslog.conf"
sed -i 's/RepeatedMsgReduction\ on/RepeatedMsgReduction\ off/' /etc/rsyslog.conf
service rsyslog restart

sed -i /usr/bin/fail2ban-client -e s,^\.setInputCmd\(c\),'time.sleep\(0\.1\)\n\t\t\tbeautifier.setInputCmd\(c\)',

#Restarting Nginx and PHP FPM
for i in freeswitch fail2ban
do service "${i}" restart  > /dev/null 2>&1
done

# see http://wiki.fusionpbx.com/index.php?title=RotateFSLogs
/bin/cat > "/etc/cron.daily/freeswitch_log_rotation" <<DELIM
#!/bin/bash

#number of days of logs to keep
NUMBERDAYS="$keep_logs"
FSPATH="/var/log/freeswitch"

/usr/bin/freeswitch_cli -x "fsctl send_sighup" |grep '+OK' >/tmp/rotateFSlogs

if [ $? -eq 0 ]; then
       #-cmin 2 could bite us (leave some files uncompressed, eg 11M auto-rotate). Maybe -1440 is better?
       find "$FSPATH" -name "freeswitch.log.*" -cmin -2 -exec gzip {} \;
       find "$FSPATH" -name "freeswitch.log.*.gz" "-mtime" "+$NUMBERDAYS" -exec /bin/rm {} \;
       chown freeswitch:freeswitch "$FSPATH"/freeswitch.log
       chmod 664 "$FSPATH"/freeswitch.log
       logger FreeSWITCH Logs rotated
       rm /tmp/<<DELIM
else
       logger FreeSWITCH Log Rotation Script FAILED
       mail -s '$HOST FS Log Rotate Error' root < /tmp/<<DELIM
       rm /tmp/<<DELIM
fi

DELIM

chmod 664 /etc/cron.daily/freeswitch_log_rotation

# restarting services
for i in php5-fpm niginx monit fail2ban freeswitch ;do service "${i}" restart  >/dev/null 2>&1 ; done

#end of fusionpbx install

#scanner blocking
echo "blocking scanners"
iptables -I INPUT -j DROP -p udp --dport 5060 -m string --string "friendly-scanner" --algo bm
iptables -I INPUT -j DROP -p udp --dport 5061 -m string --string "friendly-scanner" --algo bm
iptables -I INPUT -j DROP -p udp --dport 5062 -m string --string "friendly-scanner" --algo bm
iptables -I INPUT -j DROP -p udp --dport 5063 -m string --string "friendly-scanner" --algo bm
iptables -I INPUT -j DROP -p udp --dport 5064 -m string --string "friendly-scanner" --algo bm
iptables -I INPUT -j DROP -p udp --dport 5065 -m string --string "friendly-scanner" --algo bm
iptables -I INPUT -j DROP -p udp --dport 5066 -m string --string "friendly-scanner" --algo bm
iptables -I INPUT -j DROP -p udp --dport 5067 -m string --string "friendly-scanner" --algo bm
iptables -I INPUT -j DROP -p udp --dport 5068 -m string --string "friendly-scanner" --algo bm
iptables -I INPUT -j DROP -p udp --dport 5069 -m string --string "friendly-scanner" --algo bm
iptables -I INPUT -j DROP -p udp --dport 5080 -m string --string "friendly-scanner" --algo bm


#Install postgresql-client
if [[ $postgresql_client == "y" ]]; then
	clear
	case $(uname -m) in x86_64|i[4-6]86)
	for i in postgresql-client-9.3 php5-pgsql ;do apt-get -y install "${i}"; done
	esac
	
	case $(uname -m) in armv7l)
	echo "no are deb pkgs for pgsql postgresql-client-9.3"
	echo "postgresql-client-9.1 is being installed"
	for i in postgresql-client-9.1 php5-pgsql ;do apt-get -y install "${i}"; done
	esac
		
	service php5-fpm restart
	echo
	printf '	Please open a web-browser to http://'; ip -f inet addr show dev $net_iface | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
cat << DELIM
	Or the Doamin name assigned to the machine like http://"$(hostname).$(dnsdomainname)".
	On the First configuration page of the web user interface.
	Please Select the PostgreSQL option in the pull-down menu as your Database
	Also Please fill in the SuperUser Name and Password fields.
	On the Second Configuration Page of the web user intercae please fill in the following fields:
	Server: Use the IP or Doamin name assigned to the remote postgresql database server machine
	Port: use the port for the remote postgresql server
	Database Name: "$db_name"
	Database Username: "$db_user_name"
	Database Password: "$db_user_passwd"
	Create Database Username: Database_Superuser_Name of the remote postgresql server
	Create Database Password: Database_Superuser_password of the remote postgresql server
DELIM
fi

#install & configure basic postgresql-server
if [[ $postgresql_server == "y" ]]; then
	clear
	case $(uname -m) in x86_64|i[4-6]86)
	for i in postgresql-9.3 php5-pgsql ;do apt-get -y install "${i}"; done
	esac
	
	case $(uname -m) in armv7l)
	echo "no are deb pkgs for pgsql postgresql-client-9.3"
	echo "postgresql-9.1 is being installed"
	for i in postgresql-9.1 php5-pgsql ;do apt-get -y install "${i}"; done
	esac
	
	service php5-fpm restart
	#Adding a SuperUser and Password for Postgresql database.
	su -l postgres -c "/usr/bin/psql -c \"create role $pgsql_admin with superuser login password '$pgsql_admin_passwd'\""
	clear
echo ''
	printf '	Please open a web browser to http://'; ip -f inet addr show dev $net_iface | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'   
cat << DELIM
	Or the Doamin name asigned to the machine like http://"$(hostname).$(dnsdomainname)".
	On the First configuration page of the web user interface
	Please Select the PostgreSQL option in the pull-down menu as your Database
	Also Please fill in the SuperUser Name and Password fields.
	On the Second Configuration Page of the web user interface please fill in the following fields:
	Database Name: "$db_name"
	Database Username: "$db_user_name"
	Database Password: "$db_user_passwd"
	Create Database Username: "$pgsql_admin"
	Create Database Password: "$pgsql_admin_passwd"
DELIM
else
clear
echo ''
	printf '	Please open a web-browser to http://'; ip -f inet addr show dev $net_iface | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
cat << DELIM
	or the Doamin name asigned to the machine like http://"$(hostname).$(dnsdomainname)".
	On the First Configuration page of the web user interface "$wui_name".
	Also Please fill in the SuperUser Name and Password fields.
	Freeswitch & FusionPBX Web User Interface Installation Completed
	Now you can configure FreeSWITCH using the FusionPBX web user interface
DELIM
fi

#reboot Kernel Panic
cat > /etc/sysctl.conf << DELIM
kernel.panic = 10
DELIM

#DigiDaz Tested and approved
#set fs to run in atempfs ramdrive
cat >> /etc/fstab << DELIM
tmpfs	/tmp	tmpfs	defaults	0	0
tmpfs	/var/lib/freeswitch/db	tmpfs	defaults	0	0
tmpfs   /var/tmp	tmpfs	defaults	0	0
DELIM

#DigiDaz Tested and approved
if [[ $odroid_boards == "y" ]]; then
cat > /etc/network/if-pre-up.d/copyip << DELIM
#!/bin/bash
if [ ! -f "/boot/ip.txt ];
then
break ;;
elif [ -f "/boot/ip.txt.bak ];
then
break ;;
else
if [ -f "/boot/ip.txt ];
then
cp /boot/ip.txt /etc/network/interfaces
mv /boot/ip.txt /boot/ip.txt.bak
fi
fi
DELIM
fi

apt-get install -y --force-yes custom-scripts

#DigiDaz Tested and approved
case $(uname -m) in armv7l)
/bin/sed -i /usr/share/examples/fusionpbx/resources/templates/conf/autoload_configs/logfile.conf.xml -e 's#<map name="all" value="debug,info,notice,warning,err,crit,alert"/>#<map name="all" value="warning,err,crit,alert"/>#'
/bin/sed -i "$WWW_PATH"/"$wui_name"/app/vars/app_defaults.php -e 's#{"var_name":"xml_cdr_archive","var_value":"dir","var_cat":"Defaults","var_enabled":"true","var_description":""}#{"var_name":"xml_cdr_archive","var_value":"none","var_cat":"Defaults","var_enabled":"true","var_description":""}#'
esac

#Install openvpn openvpn-scripts 
if [[ $install_openvpn == "y" ]]; then
apt-get install openvpn openvpn-scripts
fi

#apt-get cleanup (clean and remove unused pkgs)
case $(uname -m) in armv7l)
apt-get autoclean && apt-get autoremove
esac

#Ajenti admin portal. Makes maintaining the system easier.
#ADD Ajenti repo & ajenti
if [[ $install_ajenti == "y" ]]; then
/bin/cat > "/etc/apt/sources.list.d/ajenti.list" <<DELIM
deb http://repo.ajenti.org/debian main main debian
DELIM
wget http://repo.ajenti.org/debian/key -O- | apt-key add -
apt-get update &> /dev/null && apt-get -y install ajenti
fi

echo " The install $wui_name minimal install has finished...  "
