#!/bin/bash
#Date May, 31 2014 21:38 CST
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
            This is a one time install script.
            This script is ment to be run on a fresh install of debian 7 (wheezy).
            I am working to get jessies pkgs done soon.
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
             Please take the time to refer to this document if you have install issues on openvz
             http://openvz.org/Virtual_Ethernet_device and make sure to setup a eth0 .
echo
DELIM
exit
fi
################################################################################
case $(uname -m) in armv7l)
cat << DELIM
        It is suggested you only use sqlite and or postgresql client for best preformance on 
       armhf when using a sd or emmc or nand.
       For those arm units supporting sata and usb3 harddrives you can opt for Postgrsql if you wish.
       Currently only Postgresql 9.1 is supported in the armhf pkgs. I have not foud a repo with 9.3 pkgs.
       I will update the script when I do.
DELIM
esac
################################################################################

#<------Start Edit HERE--------->

#Network Interface selection
#Default = eth0/  Proxmox VE = vmbr0
net_iface=eth0

#Please Select 1 of the followinf if using arm boards (Embedded)
#Use this setting for installing on a sd on a cubie board
#saves on writes to the sd/nand
embedded_boards="n"

#Use for configuring a odroid
odroid_boards="n"

#Required
#Stable/release=1.4/master=1.5 aka git head
# Default is stable
freeswitch_repo="stable"

#Fusionpbx repo (stable/devel)
fusionpbx_repo="devel"

# To start FreeSWITCH with -nonat option set freeswitch_NAT to y
# Set to y if on public static IP
freeswitch_nat=n

#Set how long to keep freeswitch/fusionpbx log files 1 to 30 days (Default:5)
keep_logs=5

#Dahdi & freetdm (Under Development in pkgs)(Not Yet Useable)
freeswitch_freetdm="n"

#Optional (Not Required)
# Please Select Server or Client not both.
# Used for connecting to remote postgresql database servers
# Install postgresql Client 9.x for connection to remote postgresql servers (y/n)
postgresql_client="n"

# Install postgresql server 9.x (y/n) (client included)(Local Machine)
# Notice:
# You should not use postgresql server on a nand/emmc/sd. It cuts the performance
# life in half due to all the needed reads and writes. This cuts the life of
# your pbx emmc/sd in half.
postgresql_server="n"

# Set Postgresql Server Admin username
# Lower case only
postgresql_admin=

# Set Postgresql Server Admin password
postgresql_admin_passwd=

# Set Database Name used for fusionpbx in the postgresql server
# (Default: fusionpbx)
database_name=

# Set FusionPBX database admin name.(used by fusionpbx to access
# the database table in the postgresql server.
# (Default: fusionpbx)
database_user_name=

# Set FusionPBX database admin password .(used by fusionpbx to access
# the database table in the postgresql server.

database_user_passwd=
#Extra Option's

#Install openvpn scripts
install_openvpn="n"

#Custom Dir Layout
fs_conf_dir="/etc/freeswitch"
fs_dflt_conf_dir="/usr/share/freeswitch/conf"
fs_db_dir="/var/lib/freeswitch/db"
fs_log_dir="/var/log/freeswitch"
#fs_mod_dir="/usr/lib/freeswitch/mod" (not currently used)
fs_recordings_dir="/var/lib/freeswitch/storage/recordings"
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

case $(uname -m) in armv7l)
apt-get -y update && apt-get -y dist-upgrade
for i in acpi-support-base usbmount usbutils
do apt-get -y install "${i}"
done
esac

#adding FusionPBX repo ( contains freeswitch armhf debs, and a few custom scripts debs)
case $(uname -m) in armv7l)
if [[ $freeswitch_repo == "stable" ]]; then
echo 'installing armhf stable repo'
/bin/cat > "/etc/apt/sources.list.d/voyagepbx.list" <<DELIM
deb http://repo.voyagepbx.com/deb-stable/debian/ wheezy main
DELIM

elif [[ $freeswitch_repo == "beta" ]]; then
echo 'installing armhf beta repo'
/bin/cat > "/etc/apt/sources.list.d/voyagepbx.list" <<DELIM
deb http://repo.voyagepbx.com/deb-beta/debian/ wheezy main
DELIM

elif [[ $freeswitch_repo == "head" ]]; then
echo 'installing armhf head repo'
/bin/cat > "/etc/apt/sources.list.d/voyagepbx.list" <<DELIM
deb http://repo.voyagepbx.com/deb-head/debian/ wheezy main
DELIM
fi
esac

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
if [[ $fusionpbx_repo == "stable" ]]; then
echo 'installing fusionpbx stable repo'
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

echo ' Installing freeswitch '

#install Freeswitch Deps
echo ' installing freeswitch deps '
for i in curl unixodbc uuid memcached libtiff5 libtiff-tools ghostscript ;do apt-get -y install "${i}" ; done

# install freeswitch
echo ' installing freeswitch pkgs '
for i in freeswitch freeswitch-init freeswitch-lang-en freeswitch-meta-codecs freeswitch-mod-commands freeswitch-mod-curl \
		freeswitch-mod-db freeswitch-mod-distributor freeswitch-mod-dptools freeswitch-mod-enum freeswitch-mod-esf freeswitch-mod-esl \
		freeswitch-mod-expr freeswitch-mod-fsv freeswitch-mod-hash freeswitch-mod-memcache freeswitch-mod-portaudio freeswitch-mod-portaudio-stream \
		freeswitch-mod-random freeswitch-mod-spandsp freeswitch-mod-spy freeswitch-mod-translate freeswitch-mod-valet-parking freeswitch-mod-flite \
		freeswitch-mod-pocketsphinx freeswitch-mod-tts-commandline freeswitch-mod-dialplan-xml freeswitch-mod-loopback freeswitch-mod-sofia \
		freeswitch-mod-event-multicast freeswitch-mod-event-socket freeswitch-mod-event-test freeswitch-mod-local-stream freeswitch-mod-native-file \
		freeswitch-mod-sndfile freeswitch-mod-tone-stream freeswitch-mod-lua freeswitch-mod-console freeswitch-mod-logfile freeswitch-mod-syslog \
		freeswitch-mod-say-en freeswitch-mod-posix-timer freeswitch-mod-timerfd freeswitch-mod-v8 freeswitch-mod-xml-cdr freeswitch-mod-xml-curl \
		freeswitch-mod-xml-rpc freeswitch-sounds freeswitch-music freeswitch-conf-vanilla
do apt-get -y install --force-yes "${i}"
done

case $(uname -m) in x86_64|i[4-6]86)
apt-get -y install --force-yes freeswitch-mod-shout
esac

case $(uname -m) in armv7l)
apt-get -y install --force-yes freeswitch-mod-vlc
esac

case $(uname -m) in x86_64|i[4-6]86)
if [[ $freeswitch_freetdm == y ]]; then
for i in dahdi dahdi-linux freeswitch-mod-freetdm
do apt-get -y install --force-yes "${i}"
done
fi
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

#fix permissions on the freeswitch xml_cdr dir so fusionpbx can read from it
find "$fs_log_dir"/xml_cdr -type d -exec chmod 775 {} +

#Settinf /etc/default freeswitch startup options with proper scripts dir and to run without nat.
#DISABLE NAT
if [[ $freeswitch_nat == y ]]; then
cat > "/etc/default/freeswitch" << DELIM
CONFDIR=$fs_conf_dir
DAEMON_ARGS="-u $fs_usr -g $fs_grp -rp -nonat -conf $fs_conf_dir -db $fs_db_dir -log $fs_log_dir -scripts $fs_scripts_dir -run $fs_run_dir -storage $fs_storage_dir -recordings $fs_recordings_dir -nc"
DELIM
else
cat > "/etc/default/freeswitch" << DELIM
CONFDIR=$fs_conf_dir
DAEMON_ARGS="-u $fs_usr -g $fs_grp -rp -conf $fs_conf_dir -db $fs_db_dir -log $fs_log_dir -scripts $fs_scripts_dir -run $fs_run_dir -storage $fs_storage_dir -recordings $fs_recordings_dir -nc"
DELIM
fi

service freeswitch restart

#Start of FusionPBX / nginx / php5 install
#Install and configure  PHP + Nginx + sqlite3 for use with the fusionpbx gui.
echo ' installing nginx & php & deps '

apt-get -y install sqlite3

for i in ssl-cert nginx ;do apt-get -y install "${i}" ; done

for i in php5-cli php5-common php-apc php5-gd php-db php5-fpm php5-memcache php5-odbc php-pear php5-sqlite ;do apt-get -y install "${i}" ; done

# Changing file upload size from 2M to 15M
/bin/sed -i $php_ini -e 's#"upload_max_filesize = 2M"#"upload_max_filesize = 15M"#'

#Nginx config Copied from Debian nginx pkg (nginx on debian wheezy uses sockets by default not ports)
echo ' Install NGINX config file '
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
echo "Installing FusionPBX Web User Interface via Debian pkg"

echo " Installing fusipnpbx basepbx"
for i in fusionpbx-core fusionpbx-app-calls fusionpbx-app-calls-active fusionpbx-app-contacts \
		fusionpbx-app-destinations fusionpbx-app-dialplan fusionpbx-app-dialplan-inbound \
		fusionpbx-app-dialplan-outbound fusionpbx-app-extensions fusionpbx-app-gateways \
		fusionpbx-app-fax fusionpbx-app-login fusionpbx-app-log-viewer fusionpbx-app-modules \
		fusionpbx-app-registrations fusionpbx-app-settings fusionpbx-app-sip-profiles \
		fusionpbx-app-sip-status fusionpbx-app-system fusionpbx-sounds fusionpbx-app-xml-cdr \
		fusionpbx-app-vars fusionpbx-conf fusionpbx-scripts fusionpbx-sqldb custom-scripts
do apt-get -y --force-yes install "${i}"
done

#set permissions
chmod 775 /etc/fusionpbx
chmod 775 /var/lib/fusionpbx
chmod 777 /var/lib/fusionpbx/db

mkdir -p /var/lib/fusionpbx/scripts
chown -R freeswitch:freeswitch /var/lib/fusionpbx/scripts
find "$fs_scripts_dir" -type d -exec chmod 775 {} +
find "$fs_scripts_dir" -type f -exec chmod 664 {} +

#Copy fusionpbx sounds into place
cp -rp /usr/share/fusionpbx/resources/install/sounds/* /usr/share/freeswitch/sounds/

#chown freeswitch conf files
chown -R freeswitch:freeswitch /usr/share/freeswitch/sounds

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
logpath  = /usr/local/freeswitch/log/freeswitch.log
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

"$FSPATH"/bin/freeswitch_cli -x "fsctl send_sighup" |grep '+OK' >/tmp/rotateFSlogs

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

#Install openvpn openvpn-scripts 
if [[ $install_openvpn == "y" ]]; then
for i in openvpn openvpn-scripts ;do apt-get -y install --force-yes "${i}"; done
fi

#install 
#Install postgresql-client
if [[ $postgresql_client == "y" ]]; then
	db_name="$wui_name"
	db_user_name="$wui_name"
	db_passwd="Admin Please Select A Secure Password for your Postgresql Fusionpbx Database"
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
	Database Password: "$db_passwd"
	Create Database Username: Database_Superuser_Name of the remote postgresql server
	Create Database Password: Database_Superuser_password of the remote postgresql server
DELIM
fi

#install & configure basic postgresql-server
if [[ $postgresql_server == "y" ]]; then
    db_name="$database_name"
    db_user_name="$database_user_name"
    db_passwd="$database_user_passwd"
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
	su -l postgres -c "/usr/bin/psql -c \"create role $postgresql_admin with superuser login password '$postgresql_admin_passwd'\""
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
	Database Password: "$db_passwd"
	Create Database Username: "$postgresql_admin"
	Create Database Password: "$postgresql_admin_passwd"
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

#fix for cubieboard performance
if [[ embedded_boards == "y" ]]; then
cat >> /etc/fstab << DELIM
tmpfs	/tmp	tmpfs	defaults	0	0
tmpfs	/var/lib/freeswitch/db	tmpfs	defaults	0	0
tmpfs   /var/tmp	tmpfs	defaults	0	0
DELIM
fi


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

#DigiDaz Tested and approved
case $(uname -m) in armv7l)
/bin/sed -i /usr/share/fusionpbx/resources/templates/conf/autoload_configs/logfile.conf.xml -e 's#<map name="all" value="debug,info,notice,warning,err,crit,alert"/>#<map name="all" "warning,err,crit,alert"/>#'
/bin/sed -i "$WWW_PATH"/"$wui_name"/app/vars/app_defaults.php -e 's#{"var_name":"xml_cdr_archive","var_value":"dir","var_cat":"Defaults","var_enabled":"true","var_description":""}#{"var_name":"xml_cdr_archive","var_value":"none","var_cat":"Defaults","var_enabled":"true","var_description":""}#'
esac

#apt-get cleanup (clean and remove unused pkgs)
apt-get autoclean && apt-get autoremove

echo " The install $wui_name minimal install has finished...  "
