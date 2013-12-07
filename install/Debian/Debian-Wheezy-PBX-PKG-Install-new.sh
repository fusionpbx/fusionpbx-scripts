#!/bin/bash
#Date Dec, 7 2013 16:00 EST
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
#<------Start Option Edit HERE--------->

################################################################################
# TO Disable freeswitch nat auto detection
################################################################################
# to start FreeSWITCH with -nonat option set freeswitch_NAT to y
# Set to y if on public static IP
freeswitch_nat=n

################################################################################
# Use fusionpbx debian pkgs.
################################################################################
# You should use the fusionpbx-dev pkg for now
# y=stable branch n=dev branch
fusionpbx_stable=n

#############  Please Select Server or Client not both. ########################

# ONLY NEED IF USING Posgresql Server remotely 
# Install postgresql Client 9.x for connection to remote postgresql servers (y/n)
postgresql_client=n

# Install postgresql server 9.x (y/n) (client included)(Local Machine)
# You should not use postgresql server on a emmc/sd. It cuts the performance 
# life in half due to all the needed reads and writes. This cuts the life of 
# your pbx emmc/sd in half. 
postgresql_server=n

# ONLY NEEDE IF USING Posgresql Server Localy.
# Set Postgresql Server Admin username
# Lower case only
postgresqluser=

# Set Postgresql Server Admin password
postgresqlpass=

# Set Database Name used for fusionpbx in the postgresql server 
# (Default: fusionpbx)
database_name=

# Set FusionPBX database admin name.(used by fusionpbx to access 
# the database table in the postgresql server.
# (Default: fusionpbx)
database_user_name=

#Enable pbx admin shell menu
enable_admin_menu=y

#<------Stop Options Edit Here-------->
###############################################################################
# Hard Set Varitables (Do Not EDIT)
###############################################################################
# Freeswitch logs dir
freeswitch_log="/var/log/freeswitch"
#Freeswitch default configs location
freeswitch_dflt_conf="/usr/share/freeswitch/conf"
#Freeswitch active config directory
freeswitch_act_conf="/etc/freeswitch"
#Nginx default www dir
WWW_PATH="/usr/share/nginx/www" #debian nginx default dir
#set Web User Interface Dir Name
wui_name="fusionpbx"
#Php ini config file
php_ini="/etc/php5/fpm/php.ini"
################################################################################

#start install
echo "This is a one time install script. It is not intended to be run multi times"
echo "If it fails for any reason please report to r.neese@gmail.com. Include any "
echo "screen output you can to show where it fails."
echo
echo "This Script Currently Requires a internet connection "

#check for internet connection. Pulled from and modified
#http://www.linuxscrew.com/2009/04/02/tiny-bash-scripts-check-internet-connection-availability/

wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google &> /dev/null

if [ ! -s /tmp/index.google ];then
	echo "No Internet connection. Please check ethernet cable"
	exit 1
else
	echo "continuing!"
fi

# OS ENVIRONMENT CHECKS
#check for root
if [ $EUID -ne 0 ]; then
   echo "Must Run As Root and NOT SUDO" 1>&2
   exit 1
fi

echo "You're root."

sed -i '/cdrom:/d' /etc/apt/sources.list
sed -i '2,4d' /etc/apt/sources.list

if [ ! -s /usr/bin/lsb_release ]; then
	apt-get update && apt-get -y install lsb-release
fi

# Os/Distro Check
lsb_release -c | grep -i wheezy &> /dev/null 2>&1
if [[ "$?" -eq 0 ]]; then
	echo "Found Debian 7 (wheezy)"
else
	echo "Reqires Debian 7 (Wheezy)"
	exit 1
fi

#adding FusionPBX Web User Interface repo"
case $(uname -m) in armv7l)
/bin/cat > "/etc/apt/sources.list.d/fusionpbx.list" <<DELIM
deb http://repo.fusionpbx.com wheezy main
deb-src http://repo.fusionpbx.com/ wheezy main
DELIM
for i in update upgrade ;do apt-get -y "${i}" ; done
esac

case $(uname -m) in x86_64|i[4-6]86)
apt-get install curl
/bin/cat > "/etc/apt/sources.list.d/freeswitch.list" <<DELIM
deb http://files.freeswitch.org/repo/deb/debian/ wheezy main
deb-src http://files.freeswitch.org/repo/deb/debian/ wheezy main
DELIM
#adding key for freeswitch repo
curl http://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add -
for i in update upgrade ;do apt-get -y "${i}" ; done
esac

#install Freeswitch Deps
for i in curl screen pkg-config libtiff5 libtiff-tools autotalent ladspa-sdk tap-plugins swh-plugins libfftw3-3 unixodbc uuid memcached ;do apt-get -y install "${i}" ; done

# Freeswitch Base $ Modules Install Options.
echo " Installing freeswitch all modules"
for i in freeswitch-meta-all freeswitch-mod-vlc ;do apt-get -y install "${i}" ; done

#Genertaing /etc/freeswitch config dir.
mkdir $freeswitch_act_conf

#Install FreeSwitch vanilla configs
echo " Installing freeswitch vanilla configs into the default config directory"
apt-get -y install --force-yes	freeswitch-conf-vanilla

echo " Installing freeswitch vanilla configs into the freeswitch active config directory "
cp -rp "$freeswitch_dflt_conf"/vanilla/* "$freeswitch_act_conf"

chown -R freeswitch:freeswitch "$freeswitch_act_conf"

# Proper file to change init strings in. (/etc/defalut/freeswitch)
# Configuring /etc/default/freeswitch DAEMON_Optional ARGS
sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-rp"',

#remove the default extensions
for i in /etc/freeswitch/directory/default/*.xml ;do rm "$i" ; done

# SEE http://wiki.freeswitch.org/wiki/Fail2ban
#Fail2ban
for i in fail2ban monit ;do apt-get -y install "${i}" ; done

#Taken From http://wiki.fusionpbx.com/index.php?title=Monit and edited to work with debian pkgs.
#Adding Monitor to keep freeswitch running.
/bin/cat > "/etc/monit/conf.d/freeswitch"  <<DELIM
set daemon 60
set logfile syslog facility log_daemon

check process freeswitch with pidfile /var/run/freeswitch/freeswitch.pid
start program = "/etc/init.d/freeswitch start"
stop program = "/etc/init.d/freeswitch stop"
DELIM

#Adding changes to freeswitch profiles
sed -i "$freeswitch_act_conf"/sip_profiles/internal.xml -e s,'<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>',

sed -i "$freeswitch_act_conf"/sip_profiles/internal.xml -e s,'<!-- *<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>', \
				-e s,'<param name="log-auth-failures" value="false"/> *-->','<param name="log-auth-failures" value="true"/>', \
				-e s,'<!--<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>', \
				-e s,'<param name="log-auth-failures" value="false"/>-->','<param name="log-auth-failures" value="true"/>',

#Setting up Fail2ban freeswitch config files.
/bin/cat > "/etc/fail2ban/filter.d/freeswitch.conf"  <<DELIM

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

#Turning off RepeatedMsgReduction in /etc/rsyslog.conf"
sed -i 's/RepeatedMsgReduction\ on/RepeatedMsgReduction\ off/' /etc/rsyslog.conf
/etc/init.d/rsyslog restart

sed -i /usr/bin/fail2ban-client -e s,beautifier\.setInputCmd\(c\),'time.sleep\(0\.1\)\n\t\t\tbeautifier.setInputCmd\(c\)',

#Restarting Nginx and PHP FPM
for i in freeswitch fail2ban
do /etc/init.d/"${i}" restart  >/dev/null 2>&1
done

# see http://wiki.fusionpbx.com/index.php?title=<<DELIM
/bin/cat > "/etc/cron.daily/freeswitch_log_rotation" <<DELIM
#!/bin/bash

#number of days of logs to keep
NUMBERDAYS=30
FSPATH="/var/log/freeswitch"

$FSPATH/bin/freeswitch_cli -x "fsctl send_sighup" |grep '+OK' >/tmp/<<DELIM

if [ $? -eq 0 ]; then
       #-cmin 2 could bite us (leave some files uncompressed, eg 11M auto-rotate). Maybe -1440 is better?
       find $FSPATH -name "freeswitch.log.*" -cmin -2 -exec gzip {} \;
       find $FSPATH -name "freeswitch.log.*.gz" -mtime +$NUMBERDAYS -exec /bin/rm {} \;
       chown freeswitch:freeswitch "$FSPATH"/freeswitch.log
       chmod 660 "$FSPATH"/freeswitch.log
       logger FreeSWITCH Logs rotated
       rm /tmp/<<DELIM
else
       logger FreeSWITCH Log Rotation Script FAILED
       mail -s '$HOST FS Log Rotate Error' root < /tmp/<<DELIM
       rm /tmp/<<DELIM
fi
DELIM

chmod 755 /etc/cron.daily/freeswitch_log_rotation

#Now dropping 10MB limit from FreeSWITCH"
sed -i "$freeswitch_act_conf"/autoload_configs/logfile.conf.xml -e s,\<param.*name\=\"rollover\".*value\=\"10485760\".*/\>,\<\!\-\-\<param\ name\=\"rollover\"\ value\=\"10485760\"/\>\ INSTALL_SCRIPT\-\-\>,g

# restarti9ng services
for i in fail2ban freeswitch ;do /etc/init.d/"${i}" restart  >/dev/null 2>&1 ; done

#Install and configure  PHP + Nginx + sqlite3
for i in ssl-cert sqlite3 nginx php5-cli php5-sqlite php5-odbc php-db php5-fpm php5-common php5-gd php-pear php5-memcache php-apc ;do apt-get -y install "${i}" ; done

# Changing file upload size from 2M to 15M
/bin/sed -i $php_ini -e s,"upload_max_filesize = 2M","upload_max_filesize = 15M",

#Nginx config Copied from Debian nginx pkg (nginx on debian wheezy uses sockets by default not ports)
#Install NGINX config file
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
        
        #grandstream gx2200
        rewrite "^.*/provision/cfg([A-Fa-f0-9]{12})(\.(xml|cfg))$" /app/provision/?mac=$1;
        
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

		#grandstream gx2200
        rewrite "^.*/provision/cfg([A-Fa-f0-9]{12})(\.(xml|cfg))$" /app/provision/?mac=$1;
       
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

# linking fusionpbx nginx config from avaible to enabled sites
ln -s /etc/nginx/sites-available/"$wui_name" /etc/nginx/sites-enabled/"$wui_name"

#disable default site
rm -rf /etc/nginx/sites-enabled/default

#Restarting Nginx and PHP FPM
for i in nginx php5-fpm ;do /etc/init.d/"${i}" restart > /dev/null 2>&1 ; done

#Adding users to needed groups
adduser www-data freeswitch
adduser freeswitch www-data

#adding FusionPBX Web User Interface repo"
case $(uname -m) in x86_64|i[4-6]86)
/bin/cat > "/etc/apt/sources.list.d/fusionpbx.list" <<DELIM
deb http://repo.fusionpbx.com wheezy main
deb-src http://repo.fusionpbx.com/ wheezy main
DELIM
apt-get update
esac

# Install FusionPBX Web User Interface
echo "Installing FusionPBX Web User Interface Debian pkg"

if [[ $fusionpbx_stable == y ]]; then
	apt-get -y --force-yes install fusionpbx
else
	apt-get -y --force-yes install fusionpbx-dev
fi

#"Re-Configuring /etc/default/freeswitch to use fusionpbx scripts dir"

#DAEMON_Optional ARGS
/bin/sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-scripts /var/lib/fusionpbx/scripts -rp"',

if [[ $freeswitch_nat == y ]]; then
	/bin/sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-scripts /var/lib/fusionpbx/scripts -rp -nonat"',
fi

#Clean out the freeswitch default configs from the active conf dir
rm -rf "$freeswitch_act_conf"/*

#Put Fusionpbx Freeswitch configs into place
cp -r "$WWW_PATH/$wui_name"/resources/templates/conf/* "$freeswitch_act_conf"

#chown freeswitch  conf files
chown -R freeswitch:freeswitch "$freeswitch_act_conf"

#fix permissions for "$freeswitch_act_conf" so www-data can write to it
find "$freeswitch_act_conf" -type f -exec chmod 660 {} +
find "$freeswitch_act_conf" -type d -exec chmod 770 {} +

#create xml_cdr dir
mkdir "$freeswitch_log"/xml_cdr

#chown the xml_cdr dir
chown freeswitch:freeswitch "$freeswitch_log"/xml_cdr

#fix permissions on the freeswitch xml_cdr dir so fusionpbx can read from it
find "$freeswitch_log"/xml_cdr -type d -exec chmod 770 {} +

for i in freeswitch nginx php5-fpm ;do /etc/init.d/"${i}" restart >/dev/null 2>&1 ; done

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

#restarting fail2ban
/etc/init.d/fail2ban restart

#Install postgresql-client
if [[ $postgresql_client == y ]]; then
	db_name="$wui_name"
	db_user_name="$wui_name"
	db_passwd="Admin Please Select A Secure Password for your Postgresql Fusionpbx Database"
	clear
	for i in postgresql-client-9.1 php5-pgsql
	do apt-get -y install "${i}"
	done
	/etc/init.d/php5-fpm restart
	echo
	printf '	Please open a web-browser to http://'; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
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

#install postgresql-server
if [[ $postgresql_server == y ]]; then
    db_name="$database_name"
    db_user_name="$database_user_name"
    db_passwd="$(openssl rand -base64 32;)"
	clear
	for i in postgresql-9.1 php5-pgsql
	do apt-get -y install "${i}"
	done
	/etc/init.d/php5-fpm restart
	#Adding a SuperUser and Password for Postgresql database.
	su -l postgres -c "/usr/bin/psql -c \"create role $postgresqluser with superuser login password '$postgresqlpass'\""
	clear
echo ''
	printf '	Please open a web browser to http://'; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'   
cat << DELIM
	Or the Doamin name assigned to the machine like http://"$(hostname).$(dnsdomainname)".
	On the First configuration page of the web user interface
	Please Select the PostgreSQL option in the pull-down menu as your Database
	Also Please fill in the SuperUser Name and Password fields.
	On the Second Configuration Page of the web user interface please fill in the following fields:
	Database Name: "$db_name"
	Database Username: "$db_user_name"
	Database Password: "$db_passwd"
	Create Database Username: "$postgresqluser"
	Create Database Password: "$postgresqlpass"

DELIM

else
clear
echo ''
	printf '	Please open a web-browser to http://'; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
cat << DELIM
	or the Doamin name assigned to the machine like http://"$(hostname).$(dnsdomainname)".
	On the First Configuration page of the web usre interface "$wui_name".
	Also Please fill in the SuperUser Name and Password fields.
    Freeswitch & FusionPBX Web User Interface Installation Completed.
    Now you can configure FreeSWITCH using the FusionPBX web user interface

DELIM
fi

#Install openvpn & pbx admin menu shell script.
apt-get -y install --force-yes openvpn-scripts pbx-admin-menu

#Install admin shell menu
if [[ $enable_admin_menu == y ]]; then
cat << EOF>> /root/.profile
/usr/bin/pbx-admin-menu.sh
EOF
fi

#apt-get cleanup
apt-get clean && apt-get autoremove

echo " Install Has Finished...  "