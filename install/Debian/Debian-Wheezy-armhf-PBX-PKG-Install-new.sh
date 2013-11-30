#!/bin/bash
#Date Nov, 18 2013 09:31 EST
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
# If you appreciate the work, please consider purchasing something from my
# wishlist. That pays bigger dividends to this coder than anything else I
# can think of ;). Email me and I will give the shipping address....
#
# It also keeps development of the script going for more platforms;
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

# Enable Set Database name & Database User name
# Used with the pgsql server setup amd client setup
# THis will echo the information at the end of the install for the Administrator.
set_db_info=n

# ONLY NEED IF USING Posgresql Server remotely 
# Install postgresql Client 9.x for connection to remote pgsql servers (y/n)
pgsql_client=n

# Install postgresql server 9.x (y/n) (client included)(Local Machine)
pgsql_server=n

# ONLY NEEDE IF USING Posgresql Server Localy.
# Set Postgresql Server Admin username
# Lower case only
pgsqluser=

# Set Postgresql Server Admin password
pgsqlpass=

# Set Database Name used for fusionpbx in the postgresql server 
# (Default: fusionpbx)
database_name=

# Set FusionPBX database admin name.(used by fusionpbx to access 
# the database table in the pgsql server.
# (Default: fusionpbx)
database_user_name=

#-------------------------------------------------------------------------------
#                                (UNDER DEVEL)
#-------------------------------------------------------------------------------
#Future Options not yet implamented,
#Install new admin shell menu & openvpn scripts.
install_admin_menu=n

#<------Stop Options Edit Here-------->
###############################################################################
#Check IP/FQDN
###############################################################################
echo " This install requires the system have a (FQDN) fully qualified domain name and a static ip. "
echo " This is due to the Mail Trandport Agent pkgs looking for a FQDN "
echo " So if you have not set a static ip and a fqdn please answer n to the next question. It will "
echo " then allow you to configure the network ip and fqdn. Then it will continue on with th install."
echo " Note you can change these at anytime from the admin menu."
echo
read -p "Does your system have a static ip and a fqdn if yes hit enter else if no hit (n/N/enter)"
if [[ $REPLY =~ ^[Nn]$ ]]
then
# Configure hostename
read -r -p "Please set your system hostname (example: pbx):" HN
read -r -p "Please set your system domain name (example: mydomain.com):" DN
# Configure WAN network interface
read -r -p "Please  set your system IP (local ip or domain ip)  :" IP
read -r -p "Please enter the network mask :" NM
read -r -p "Please enter the network gateway :" GW
read -r -p "Please enter the primary dns source:" NS1
read -r -p "Please enter the secondary dns source :" NS2
cat << EOF > /etc/network/interfaces
# The loopback network interface
auto lo
iface lo inet loopback
# The primary network interface
allow-hotplug eth0
iface eth0 inet static
      address $IP
      netmask $NM
      gateway $GW
      dns-nameservers $NS1 $NS2
EOF

cat << EOF > /etc/hosts
127.0.0.1       localhost $HN
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
$IP     $HN.$DN $HN
EOF

cat << EOF > /etc/hostname
$HN
EOF

hostname $HN

echo "Rebooting for networkign changes to take effect."
echo "You will need to relogin and restart the script."
echo "when it ask you the fqdn/ip question just hit enter and it will continue."
echo "Please ssh to $IP and relogin"

reboot
exit 1
fi

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
echo "This is a one time install script. If it fails for any reason please report"
echo "to r.neese@gmail.com . Include any screen output you can to show where it"
echo "fails."
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
lsb_release -c |grep -i wheezy > /dev/null

if [[ $? -eq 0 ]]; then
	DISTRO=wheezy
	echo "Found Debian 7 (wheezy)"
else
	echo "Reqires Debian 7 (Wheezy)"
	exit 1
fi

#dding FusionPBX Web User Interface repo"
/bin/cat > "/etc/apt/sources.list.d/fusionpbx.list" <<DELIM
deb http://repo.fusionpbx.com wheezy main
deb-src http://repo.fusionpbx.com/ wheezy main
DELIM

#Updating OS and installed pre deps
for i in update upgrade ;do apt-get -y "${i}" ; done

#install (MTA) Mail Transport Agent
apt-get install $MTA

#install Freeswitch Deps
for i in curl screen pkg-config libtiff5 libtiff-tools autotalent ladspa-sdk tap-plugins swh-plugins libfftw3-3 unixodbc uuid memcached ;do apt-get -y install "${i}" ; done

# Freeswitch Base $ Modules Install Options.
echo " Installing freeswitch all modules"
apt-get -y install --force-yes freeswitch-meta-all freeswitch-mod-vlc

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
for i in /etc/freeswitch/directory/default/*.xml ;do rm $i ; done

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

#setting database name /user name / password
if [[ $set_db_info == y ]]; then
    db_name="$database_name"
    db_user_name="$database_user_name"
    db_passwd="$(openssl rand -base64 32;)"
else
	db_name="$wui_name"
	db_user_name="$wui_name"
	db_passwd="Admin Please Select A Secure Password for your Postgresql Fusionpbx Database"
fi

#Install pgsql-client
if [[ $pgsql_client == y ]]; then
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
	Port: use the port for the remote pgsql server
	Database Name: "$db_name"
	Database Username: "$db_user_name"
	Database Password: "$db_passwd"
	Create Database Username: Database_Superuser_Name of the remote pgsql server
	Create Database Password: Database_Superuser_password of the remote pgsql server

DELIM

fi

#install pgsql-server
if [[ $pgsql_server == y ]]; then
	clear
	for i in postgresql-9.1 php5-pgsql
	do apt-get -y install "${i}"
	done

	/etc/init.d/php5-fpm restart

	#Adding a SuperUser and Password for Postgresql database.
	su -l postgres -c "/usr/bin/psql -c \"create role $pgsqluser with superuser login password '$pgsqlpass'\""
	clear
	echo
	echo
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
	Create Database Username: "$pgsqluser"
	Create Database Password: "$pgsqlpass"

DELIM

else

clear

echo
echo
	printf '	Please open a web-browser to http://'; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
cat << DELIM

	or the Doamin name assigned to the machine like http://"$(hostname).$(dnsdomainname)".

    on the First Configuration page of the web usre interface "$wui_name".

	also Please fill in the SuperUser Name and Password fields.

    Freeswitch & FusionPBX Web User Interface Installation Completed.

    Now you can configure FreeSWITCH using the FusionPBX web user interface

                         Please reboot your system
DELIM

fi

# Installing OpenVPN config scripts
#confgen
/bin/cat > "/usr/bin/confgen" <<DELIM
#!/bin/bash
#########################################################################
##### Openvpn Confgen ##                        ##  2010may07 v0.1  #####
#########################################################################
##### released as public domain. ##        ##  thanks to Bushmills  #####
#########################################################################
#####                 by krzee @ Freenode #OpenVPN                  #####
#####       Just run ./confgen            chmod +x all 3 files      #####
#####                                                               #####
# This is a bash script To help you generate configuration files    #####
# for some of the most commonly desired vpn setups. You can setup   #####
# lans behind server / clients, or redirect client internet through #####
# the server							    #####
# Todo                                                              #####
# -Allow multiple lans behind each node                             #####
# -I should ask if each client should have internet redirected.     #####
#  currently it is all or none                                      #####
# -I will also generate certificates, performing the role of CA     #####
#  server                                                           #####
#####                                                               #####
#########################################################################

shopt -s nocasematch
valid_ip()
{
  local  ip=$1
  stat=4
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
     ip=(${ip//./ })
     for i in {0..3}; do
        ((stat -= ip[i]<256))
     done
  fi
  return $((stat&&1))
}

cat << EOF
YOU MUST USE 2.1.x FOR THESE CONFIGS
PRESS ENTER FOR DEFAULT
EOF
while : ;do

cat << EOF
What IP does this server listen to for OpenVPN connections?
LAN IP if behind a NAT (like a dsl/cablemodem router)
Default is it runs on all ips (0.0.0.0)
EOF
c="0" ; z="0" ; y="0"
read LISTENIP
: ${LISTENIP:=0.0.0.0}
valid_ip ${LISTENIP} && break
done
arg[c++]="-L"
arg[c++]="${LISTENIP}"

while [ -z "${SERVERIP}" ] ;do
  cat <<EOF
What Hostname or IP do clients use to reach the server?
If server is on dynamic IP get a dyndns and enter that here
EOF
  read SERVERIP
done
carg[z++]="-S"
carg[z++]="${SERVERIP}"

while ! ((SERVERPORT > 0 && SERVERPORT < 65536)) ;do
  echo
  echo "what port does this server listen on?"
  echo "Default = 1194"
  read SERVERPORT
  : ${SERVERPORT:=1194}
done
arg[c++]="-p"
arg[c++]="${SERVERPORT}"
carg[z++]="-p"
carg[z++]="${SERVERPORT}"

echo
echo "What protocol will you tunnel over? Use UDP if possible!"
echo "Default is udp"
while : ;do
echo "(udp/tcp)"
read PROTO
case "${PROTO}" in
  udp) break
  ;;
  tcp) break
  ;;
   "") PROTO=udp ; break
  ;;
esac
done
arg[c++]="-P"
arg[c++]="${PROTO}"
carg[z++]="-P"
carg[z++]="${PROTO}"

echo
echo "Is the server running on windows?"
while : ;do 
read -p "(y/n) " job
case "${job}" in
  y) SERVERWINDOWS="1"
     while [ -z "${SKEYDIR}" ] ;do
       echo
       echo "What is the full path to the directory the server will keep its keys in?"
       read -rp "ie: C:\\Program Files\\OpenVPN\\config\\keys
    " SKEYDIR
     done
     SKEYDIR=`echo "${SKEYDIR}" |sed -e 's,\\\\,\\\\\\\\,g'`
     arg[c++]="-K"
     arg[c++]="\"${SKEYDIR}\""
     echo
     echo "Remember to disable windows firewall on TAP adapter, and during testing disable it all together"
     break
  ;;
  n) while [ -z "${SKEYDIR}" ] ;do
       echo
       echo "What is the full path to the directory the server will keep its keys in?"
       echo "ie: /etc/openvpn/server/keys"
       read SKEYDIR
     done
     arg[c++]="-K"
     arg[c++]="\"${SKEYDIR}\""
     while [ -z "${vpnuser}" ] ;do
       echo
       echo "What user do you want to drop privileges to after startup?"
       echo "You must still start OpenVPN as root! After it does what it needs as root it will drop permissions to this"
       read vpnuser
     done
     arg[c++]="-U"
     arg[c++]="${vpnuser}"
     while [ -z "${vpngroup}" ] ;do
       echo
       echo "What group do you want to drop privileges to after startup?"
       read vpngroup
     done
     arg[c++]="-G"
     arg[c++]="${vpngroup}"
     break
  ;;
esac
done

while [ -z "${VPNSUBNET}" ] ;do
echo
echo "What subnet will the VPN hand out? ie: 10.8.1.0 255.255.255.0"
echo "Make sure it is different than any LAN the server or any client are on"
echo "Default: 10.8.1.0 255.255.255.0"
read VPNSUBNET
: ${VPNSUBNET:="10.8.1.0 255.255.255.0"}
if ((  $(wc -w <<< "$VPNSUBNET") != 2 )); then unset VPNSUBNET ; continue; fi
read -r VPNNET VPNNETMASK <<< "${VPNSUBNET}"
valid_ip ${VPNNET} || unset VPNSUBNET
valid_ip ${VPNNETMASK} || unset VPNSUBNET
done
arg[c++]="-V"
arg[c++]="${VPNSUBNET}"

cat << EOF

Should client to client traffic stay within the OpenVPN server process and not hit the kernel?
Yes will route traffic from 1 client to another inside the Openvpn server process instead of the OS knowing about it
No will allow you to firewall client to client traffic
Default: yes
EOF
while : ;do
read -p "(y/n) " job
case "$job" in
  y) arg[c++]="-C"
     break
  ;;
  n) break
  ;;
  "") arg[c++]="-C"
     break
  ;;
esac
done

echo
default=5
echo "What verbosity for logfiles?"
echo "5 for debugging, 3 for normal usage"
echo "Default: $default"
while : ;do
read -rp "(1-9)" VERB
case "${VERB}" in
  [1-9]) break
  ;;
  "") VERB=$default
      break
  ;;
esac
done
arg[c++]="-v"
arg[c++]="${VERB}"
carg[z++]="-v"
carg[z++]="${VERB}"

echo
echo "Will the server share its LAN with the VPN?"
echo "Default: no"
while : ;do
read -rp "(y/n)" job
case "${job}" in
  y) while [ -z "${SERVERLAN}" ] ;do
     echo
     echo "What is the LAN subnet?"
     echo "Make sure this lan is uncommon if you have traveling clients"
     echo "ie: 192.168.20.0 255.255.255.0"
     read SERVERLAN
     if ((  $(wc -w <<< "$SERVERLAN") != 2 )); then unset SERVERLAN ; continue; fi

     while read -r SERVERNET SERVERNETMASK; do
       valid_ip ${SERVERNET} || unset SERVERLAN
       valid_ip ${SERVERNETMASK} || unset SERVERLAN
     done <<< "${SERVERLAN}"

     done
     arg[c++]="-l"
     arg[c++]="${SERVERLAN}"
     break
  ;;
  n) break
  ;;
 "") break
  ;;
esac
done

echo
echo "Enable Compression?"
echo "OpenVPN must be compiled with compression to enable this"
echo "Default: yes"
while : ;do
read -p "(y/n) " job
case "${job}" in
  y) arg[c++]="-Z"
     carg[z++]="-Z"
     break
  ;;
  n) break
  ;;
 "") arg[c++]="-Z"
     carg[z++]="-Z"
     break
  ;;
esac
done

echo
echo "Do you want clients to send all their internet traffic through the server?"
echo "Default: no"
while : ;do
read -p "(y/n) " job
case "${job}" in
  y) arg[c++]="-R"
     echo
     echo "Be sure to setup NAT for $VPNSUBNET" 
     [ -z "${SERVERWINDOWS}" ] &&
     echo "Linux ie: iptables -t nat -A POSTROUTING -s ${VPNNET}/${VPNNETMASK} -o eth0 -j MASQUERADE" ||
     echo "See: http://www.windowsnetworking.com/articles_tutorials/NAT_Windows_2003_Setup_Configuration.html"
     echo
     echo "Be sure to enable IP forwarding on the server"
     [ -z "${SERVERWINDOWS}" ] &&
     (echo "Linux: net.ipv4.ip_forward = 1 in sysctl.conf"; echo "FBSD: gateway_enable="YES" in /etc/rc.conf") || 
     echo "See: http://support.microsoft.com/kb/315236"
     break
  ;; 
  n) break
  ;;
 "") break
  ;;
esac
done

getccd()
{
if [ -z "${CCD}" ] ;then
  while [ -z "${CCD}" ] ;do
   cat << EOF

   You have a client with a LAN behind it, you will need to enable ccd entries on the server
   this uses client-config-dir to add per-client entries in to server.conf
   What is the full path to the directory you want your ccd entries in?
   Remember that the server needs read access to this directory while running.
EOF
   if [ -n "${SERVERWINDOWS}" ] ;then
      read -rp "ie: C:\\Program Files\\OpenVPN\\config\\ccd
    " CCD
      CCD=`echo "$CCD"|sed -e 's,\\\\,\\\\\\\\,g'`
   else
      read -p "ie: /etc/openvpn/server/ccd" CCD
   fi
  done
  arg[c++]="-D"
  arg[c++]="\"$CCD\""
  mkdir ccd
fi
}

echo
echo "Do you have a client with a LAN behind it which should be able to access the VPN?"
echo "Default: no"
while : ;do
read -p "(y/n) " job
case "${job}" in
  y) getccd
     while [ -z "${CN}" ] ;do
       echo
       read -rp "what is the EXACT common-name of the client whose LAN you want to route over? " CN
     done
     while [ -z "${CSUBNET}" ] ;do
       echo
       echo "what LAN subnet is behind it?"
       echo "ie: 192.168.10.0 255.255.255.0"
       read CSUBNET
       if ((  $(wc -w <<< "$CSUBNET") != 2 )); then unset CSUBNET ; echo "error, enter a NETWORK and NETMASK"; continue; fi
       read -r CNET CNETMASK <<< "${CSUBNET}"
       ! valid_ip ${CNET} && echo "$CNET is not a valid IP" && unset CSUBNET
       ! valid_ip ${CNETMASK} && echo "$CNETMASK is not a valid IP" && unset CSUBNET
     done
     CLANCN[y]="${CN}"
     arg[c++]="-c"
     arg[c++]="${CLANCN[$y]} ${CSUBNET}"
     echo "iroute \"${CSUBNET}\"" > ccd/${CLANCN[$y]}
     echo "make sure you place the file `pwd`/ccd/${CLANCN[y++]} into ${CCD}/ on your server"
     unset CN CSUBNET 
     echo
     echo "Do you have another client with a LAN behind it which should be able to access the VPN?"
     echo "Default: no"
     continue
  ;;
  n) break
  ;;
 "") break
  ;;
esac
done

echo
echo "What is the server's name?"
echo "I will use this for key/cert/config filenames"
echo "Default: server"
read SNAME
: ${SNAME:="server"}
arg[c++]="-o"
[ -n "${SERVERWINDOWS}" ] && arg[c++]="${SNAME}.ovpn" || arg[c++]="${SNAME}.conf"
echo "Generating Server config"
./genserver.sh "${arg[@]}"
zarg=("${carg[@]}")
makeclient()
{
  echo
  echo "Is $client running on windows?"
  while : ;do
  read -rp "(y/n) " job
  case "${job}" in
    y) CWIN="1"
      while [ -z "${CKEYDIR}" ] ;do
       echo
       echo "What is the full path to the directory $client will keep its keys in?"
       read -rp "ie: C:\\Program Files\\OpenVPN\\config\\keys
   " CKEYDIR
       CKEYDIR=`echo "${CKEYDIR}" |sed -e 's,\\\\,\\\\\\\\,g'`
      done
       carg[z++]="-K"
       carg[z++]="\"${CKEYDIR}\""
       unset CKEYDIR
       echo
       echo "Remember to disable windows firewall on TAP adapter, and during testing disable it all together"
       break
    ;;
    n) while [ -z "${CKEYDIR}" ] ;do
       echo
       echo "What is the full path to the directory $client will keep its keys in?"
       read -rp "ie: /etc/openvpn/config/keys " CKEYDIR
       done
       carg[z++]="-K"
       carg[z++]="\"${CKEYDIR}\""
       while [ -z "${vpnuser}" ] ;do
         echo
         echo "What user do you want to drop privileges to after startup?"
         echo "You must still start OpenVPN as root! After it does what it needs as root it will drop permissions to this"
         read vpnuser
       done
       carg[z++]="-U"
       carg[z++]="${vpnuser}"
       while [ -z "${vpngroup}" ] ;do
         echo
         echo "What group do you want to drop privileges to after startup?"
         read vpngroup
       done
       carg[z++]="-G"
       carg[z++]="${vpngroup}"
       unset CKEYDIR vpnuser vpngroup
       break
    ;;
  esac
  done
  carg[z++]="-o"
  [ -n "${CWIN}" ] && carg[z++]="${client}.ovpn" || carg[z++]="${client}.conf"
  echo "Generating client config for $client"
  ./genclient.sh "${carg[@]}"
  carg=("${zarg[@]}")
}

echo "Generating Client config(s)"
if [ -n "${CLANCN}" ] ;then
   for client in ${CLANCN[@]} ;do
   makeclient
   done
   C="1"
fi
[ -z "${C}" ] && while [ -z "${client}" ] ;do echo "What is the client common-name?" && read client ;done && makeclient

while : ;do
echo
echo "Do you Want to generate another client config?"
echo "Default: no"
read -p "(y/n) " job
case "${job}" in
  y) unset client
     while [ -z "${client}" ]; do
        read -p "What is the client common-name? " client
     done
     makeclient
     continue
  ;;
  n) break
  ;;
 "") break
  ;;
esac
done
DELIM

#genclient.sh
/bin/cat > "/usr/bin/genclient.sh" <<DELIM
#!/bin/bash
#########################################################################
##### Openvpn Confgen ##                        ##  2010may07 v0.1  #####
#########################################################################
##### released as public domain. ##        ##  thanks to Bushmills  #####
#########################################################################
#####                 by krzee @ Freenode #OpenVPN                  #####
#####       Just run ./confgen            chmod +x all 3 files      #####
#####                                                               #####
# This is a bash script To help you generate configuration files for     
# some of the most commonly desired vpn setups.  You can setup lans      
# behind server / clients, or redirect client internet through the server
# Todo                                                                   
# -Allow multiple lans behind each node                             #####
# -I should ask if each client should have internet redirected.     #####
#  currently it is all or none                                      #####
# -I will also generate certificates, performing the role of CA     #####
#  server                                                           #####
#####                                                               #####
#########################################################################

help()
{
  cat <<EOF
Name:
     genclient -- This script sets up the OpenVPN client config
Synopsis:
     genclient [-Z] [-v verbosity] [-U user] [-G group] [-p port] [-P protocol] [-o outputfile] -S hostname -K keydir
Options:
     -h   - Help.  This message!
     -S   - The hostname or IP of the server
     -p   - Port of the server
     -P   - protocol of the server (udp/tcp)
     -U   - Username to run as (not for windows)
     -G   - Group to run as (not for windows)
     -K   - Directory of the clients keys on the client machine.
            For windows this must be formatted like '"C:\\Program Files\\OpenVPN\\config"'
            With both single & double quotes and escaped backslashes
     -v   - Verbosity level. Between 1 and 9 (3 is good for normal, 5 for debug)
     -Z   - Enable compression (requires lzo compiled in)
     -o   - Output file for the config
Example:
genclient -Z -o krzee.conf -S vpnhost.com -K '"C:\\Program Files\\OpenVPN\\config\\keys"'

  This would configure a client with compression, verbosity of 4, connecting to vpnhost.com on 1194 udp
It would be set to find its keys in C:\Program Files\OpenVPN\config\keys
EOF
  exit 0
}
[ -z "$1" ] && help
unset USER
while [ -n "$1" ]; do
case $1 in
    -h) help;shift 1;;          # function help is called
    -S) SERVERIP="$2";shift 2;;
    -p) PORT="$2";shift 2;;
    -P) PROTO="$2";shift 2;;
    -U) USER="$2";shift 2;;
    -G) GROUP="$2";shift 2;;
    -K) KEYDIR="$2";shift 2;;
    -v) VERB="$2";shift 2;;
    -Z) COMPRESS="1";shift 1;;
    -o) CONFIG="$2";shift 2;;
    --) shift;break;; # end of options
    -*) echo "error: no such option $1. -h for help";exit 1;;
    *)  break;;
esac
done

[ -z "${SERVERIP}${KEYDIR}" ] && help     # not sure - was this OR condition? then this is wrong now
: ${PORT:=1194}
: ${PROTO:=udp}
: ${VERB:=4}
: ${CONFIG:="client.ovpn"}
CN=${CONFIG%.*}

(cat << EOF
# If there is ANYTHING in this config which you do not understand, read the openvpn manual
# Look up the first word in the manual, ie: to learn about the client
#  Command, look up --client in the man page
# Made for openvpn 2.1.x
client
dev tun
remote $SERVERIP $PORT $PROTO
resolv-retry infinite
nobind
cd $KEYDIR
ca ca.crt
cert ${CN}.crt
key ${CN}.key
tls-auth ta.key 1
persist-key
persist-tun
verb $VERB
EOF
echo -ne "${USER:+user $USER\n}"
echo -ne "${GROUP:+group $GROUP\n}"
echo -ne "${COMPRESS:+comp-lzo\n}"
) > $CONFIG
DELIM

#GENSERVER.sh
/bin/cat > "/usr/bin/genserver.sh" <<DELIM
#!/bin/bash
#########################################################################
##### Openvpn Confgen ##                        ##  2010may07 v0.1  #####
#########################################################################
##### released as public domain. ##        ##  thanks to Bushmills  #####
#########################################################################
#####                 by krzee @ Freenode #OpenVPN                  #####
#####       Just run ./confgen            chmod +x all 3 files      #####
#####                                                               #####
# This is a bash script To help you generate configuration files for     
# some of the most commonly desired vpn setups.  You can setup lans      
# behind server / clients, or redirect client internet through the server
# Todo                                                                   
# -Allow multiple lans behind each node                             #####
# -I should ask if each client should have internet redirected.     #####
#  currently it is all or none                                      #####
# -I will also generate certificates, performing the role of CA     #####
#  server                                                           #####
#####                                                               #####
#########################################################################

help()
{
  cat <<EOF
Name:
     genserver - Script that sets up the OpenVPN server config
                 You must have openvpn 2.1+ to use this.

Synopsis:
     genserver [-Z] [-R] [-C] [-v verbosity] [-U user] [-G group] [-p port] [-P protocol] [-o outputfile]
               [-L ip] [-V network] [-l "network netmask"] [-D ccd_dir [-c "CN network netmask"]] -K keydir

Options:
     -h   - Help.  This message!
     -L   - IP to bind to on local interface.  0.0.0.0 if not used.
     -p   - Port of the server (default=1194)
     -P   - protocol of the server (udp/tcp, default=udp)
     -U   - Username to run as (not for windows)
     -G   - Group to run as (not for windows)
     -K   - Directory of the servers keys on the server.
            For windows this must be formatted like: -K '"C:\\Program Files\\OpenVPN\\config"'
            With both single & double quotes and escaped backslashes
     -V   - Subnet to use for VPN clients. (default=10.8.1.0)
     -C   - Use to enable --client-to-client config option
     -c   - Configures client lan.  Needs the client common-name, network, and network.
            example: -c "krzee 192.168.5.0 255.255.255.0"
            this will create ccd entry, and setup routes. REQUIRES -D
     -l   - Enables routing the Server LAN over the VPN. Must be quoted network netmask.  
            example: -l "192.168.10.0 255.255.255.0"
     -R   - Use to enable --push "redirect-gateway def1"
            This will force client internet through the VPN
            You must NAT the vpn subnet and enable ip forwarding, both on your server.
     -v   - Verbosity level. Between 1 and 9 (3 is good for normal, 5 for debug)
     -Z   - Use to enable compression (requires lzo compiled in)
     -o   - Output file for the config (default=server.ovpn)
     -D   - Directory for CCD config files, you need this for lans behind clients and static vpn ips.
            If you do not use -D you will not have CCD files

Example:
genclient -Z -C -v 3 -p 1194 -P udp -o server.conf -L 10.0.0.1 -K "/etc/openvpn" -l "10.0.0.0 255.255.255.0" -D "/etc/openvpn/ccd" -c "krzee 192.168.5.0 255.255.255.0" -V 10.8.1.0

  This would configure the server to use compression, enable client-to-client routing inside the server process,
set the log verbosity to 3, run the server on 1194 udp, setup keys the be in /etc/openvpn/ in the config, 
configure routing for a server lan of 10.0.0.0/24 and client lan behind krzee with a lan of "192.168.5.0/24,
and it would use 10.8.1.0/24 for vpn clients.  

genclient -R -Z -L 10.0.0.1 -K '"C:\\Program Files\\OpenVPN\\config"'

  This would configure a server config that would force users to route internet through the server over the vpn.
Note, you must enable IP forwarding and NAT on your server OS for this to work.
It would run on port 1194 udp, output to server.ovpn, use a verb of 4, and a vpn subnet of 10.8.1.0/24

EOF
  exit 1
}
[ -z "$1" ] && help
c=0
unset SERVERUSER
while [ -n "$1" ]; do
case $1 in
    -h) help;shift 1;;          # function help is called
    -L) SERVERLISTENIP="$2";shift 2;;
    -p) SERVERPORT="$2";shift 2;;
    -P) PROTO="${2}";shift 2;;
    -U) SERVERUSER="$2";shift 2;;
    -G) SERVERGROUP="$2";shift 2;;
    -K) KEYDIR="$2";shift 2;;
    -V) VPNSUBNET="$2";shift 2;;
    -C) C2C="1";shift 1;;
    -v) VERB="$2";shift 2;;
    -l) SERVERSUBNET="$2";shift 2;;
    -Z) COMPRESS="1";shift 1;;
    -R) REDIRECT="1";shift 1;;
    -o) CONFIG="$2";shift 2;;
    -c) CLAN[c++]="$2";shift 2;;
    -D) CCD="$2";shift 2;;
    --) shift;break;; # end of options
    -*) echo "error: no such option $1. -h for help";exit 1;;
    *)  break;;
esac
done
[ -z "$KEYDIR" ] && help
: ${SERVERPORT:=1194}
: ${PROTO:="udp"}
: ${VPNSUBNET:="10.8.1.0"}
: ${VERB:=4}
: ${CONFIG:="server.ovpn"}
CN=${CONFIG%.*}
[ -z "$CCD" -a -n "$CLAN" ] && (echo "You can not have a client LAN without CCD entries"; help)
(
cat << EOF
# If there is ANYTHING in this config which you do not understand, read the openvpn manual
# Look up the first word in the manual, ie: to learn about the local
#  Command, look up --local in the man page
# Made for openvpn 2.1.x
port $SERVERPORT
proto $PROTO
dev tun
cd $KEYDIR
ca ca.crt
cert ${CN}.crt
key ${CN}.key
dh dh2048.pem
tls-auth ta.key 0
server $VPNSUBNET
persist-key
persist-tun
topology subnet
keepalive 10 120
verb $VERB
EOF
echo -ne "${SERVERLISTENIP:+local $SERVERLISTENIP\n}"
echo -ne "${CCD:+client-config-dir $CCD\n}"
echo -ne "${SERVERUSER:+user $SERVERUSER\n}"
echo -ne "${SERVERGROUP:+group $SERVERGROUP\n}"
echo -ne "${C2C:+client-to-client\n}"
echo -ne "${COMPRESS:+comp-lzo\n}"
echo -ne "${REDIRECT:+push \"redirect-gateway def1\"\n}"
echo -ne "${SERVERSUBNET:+push \"route $SERVERSUBNET\"  # Lan behind server\n}"
while ((c--)); do
  read CLANCN CSUBNET <<< "${CLAN[c]}"
  echo "push \"route $CSUBNET\"  # Lan behind ${CLANCN}"
  echo "route $CSUBNET  # Lan behind ${CLANCN}" 
done ) >$CONFIG
exit 0
DELIM


#chmod these files to be executable
for i in confgen genclient.sh genserver.sh ;do chmod +x /usr/bin/${i} ; done


#Install admin shell menu
if [[ $install_admin_menu == y ]]; then
/bin/cat > "/usr/bin/debian.menu" <<DELIM
#!/bin/bash
#Date AUG, 14 2013 18:20 EST
################################################################################
# The MIT License (MIT)
#
# Copyright (c) <2013> Richard Neese <r.neese@gmail.com>
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
################################################################################

set -eu

#Base Varitables
USRBASE="/usr"
BACKUPDIR="/root/pbx-backup"

#Freeswitch Directories
# Freeswitch logs dir
FS_LOG="/var/log/freeswitch"

#freeswitch db/recording/storage/voicemail/fax dir
FS_LIB="/var/lib/freeswitch"
FS_DB="/var/lib/freeswitch/db"
FS_REC="/var/lib/freeswitch/recordings"
FS_STOR="/var/lib/freeswitch/storage"

#freeswitch modules dir
FS_MOD="/usr/lib/freeswitch/mod"

#defalt configs dir / grammer / lang / sounds
FS_DFLT_CONF="/usr/share/freeswitch/conf"
FS_GRAM="/usr/share/freeswitch/grammar"
FS_LANG="/usr/share/freeswitch/lang"
FS_SCRPT="/usr/share/freeswitch/scripts"

#Freeswitch Sounds Dir
FS_SNDS="/usr/share/freeswitch/sounds"

#Freeswitch active config files
FS_ACT_CONF="/etc/freeswitch"

#WWW directory
WWW_PATH="$USRBASE/share/nginx/www"

#WUI Name
WUI_NAME="fusionpbx"

#Fusionpbx DB Dir
FPBX_DB="/var/lib/fusionpbx/db"

#FusionPBX Scripts Dir (DialPLan Scripts for use with Freeswitch)
FPBX_SCRPT="/var/lib/fusionpbx/scripts"

################################################################

# Disacle CTL C (Disable CTL-C so you can not escape the menu)
#trap "" SIGTSTP
trap "" 2

# Reassign ctl+d to ctl+_
stty eof  '^_'

# Set Root Password
set_root_password(){
/usr/bin/passwd
}

# Set System Time Zone
set_local_tz(){
/usr/sbin/dpkg-reconfigure tzdata
}

# Setup Primary Network Interface
set_net_1(){
# Configure hostename
read -r -p "Please set your system hostname (pbx):" HN
read -r -p "Please set your system domainname (mydomain.com):" DN
# Configure WAN network interface
read -r -p "Please  set your system doman IP (Same as the Domain IP ) :" IP
read -r -p "Please enter the network mask :" NM
read -r -p "Please enter the network gateway :" GW
read -r -p "Please enter the primary dns source:" NS1
read -r -p "Please enter the secondary dns source :" NS2
read -r -p "Please enter the dns search domain :" SD
cat << EOF > /etc/network/interfaces
# The loopback network interface
auto lo
iface lo inet loopback
# The primary network interface
allow-hotplug eth0
iface eth0 inet static
      address $IP
      netmask $NM
      gateway $GW
      dns-nameservers $NS1 $NS2
EOF

cat << EOF > /etc/hosts
127.0.0.1       localhost $HN
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
$IP     $HN.$DN $HN
EOF

cat << EOF > /etc/hostname
$HN
EOF
}

# Setup Secondary Network Interface
set_net_2(){
# Configure LAN network interface
read -r -p "Please  set your system doman IP (Same as the Domain IP ) :" IP
read -r -p "Please enter the network mask :" NM
read -r -p "Please enter the network gateway :" GW

cat << EOF >> /etc/network/interfaces
# The secondary network interface
allow-hotplug eth1
iface eth0 inet static
        address $IP
        netmask $NM
        gateway $GW
EOF
}

# Start/Stop/Restart Web Services
web_options(){
while : ;do
list_web_options
 read -r web
 case "$web" in
 start|stop|restart) break ;;
  1) web="start" && break ;;
  2) web="stop" && break ;;
  3) web="restart" && break ;;
  4) return ;;
  *) continue ;;
 esac
done

/etc/init.d/nginx $web  >/dev/null 2>&1
/etc/init.d/php5-fpm $web  >/dev/null 2>&1
}

list_web_options(){
cat << EOF
1) start
2) stop
3) restart
4) Return to main menu
Choice:
EOF
}

# Setup/configure OpenVPN
set_vpn(){
while : ;do
$USRBASE/bin/confgen
done
}

# Factory Reset System
factory_reset(){
echo "This will wipe and set your system back to factory default"
echo "it will remove all call detail records / custom conifgs / "
echo " sounds / recordings / faxes / and reset the gui. "
while : ;do
read -p "Are you sure you wish to factory reset you pbx? (y/Y/n/N)"
case "$REPLY" in
 n|N) break ;;
 y|Y)

# stop system services
for i in nginx php5-fpm fail2ban freeswitch
do /etc/init.d/"${i}" stop > /dev/null 2>&1
done

# remove freeswitch related files
rm -f "$FS_DB"/* "$FS_LOG"/*.log "$FS_LOG"/freeswitch.xml.fsxml
rm -rf "$FS_LOG"/xml-cdr/* "$FS_STOR"/fax/* "$FS_REC"/*

rm -rf "$FPBX_SCRPT"/*

#Put Fusionpbx Freeswitch configs into place
cp -r "$WWW_PATH"/"$WUI_NAME"/resources/install/scripts/* "$FPBX_SCRPT"

#chown freeswitch script files
chown -R freeswitch:freeswitch "$FPBX_SCRPT"

#Clean out the freeswitch conf dir
rm -rf "$FS_ACT_CONF"/*

#Put Fusionpbx Freeswitch configs into place
cp -r "$WWW_PATH"/"$WUI_NAME"/resources/templates/conf/* "$FS_ACT_CONF"

#chown freeswitch  conf files
chown -R freeswitch:freeswitch "$FS_ACT_CONF"

#fix permissions for "$FS_ACT_CONF" so www-data can write to it
find "$FS_ACT_CONF" -type f -exec chmod 660 {} +
find "$FS_ACT_CONF" -type d -exec chmod 770 {} +

# remove fusionpbx db and config files

if exists "$FBPX_DB"/fusionpbx.db 
then
rm -f "$FBPX_DB"/fusionpbx.db
fi

rm -f "$WWW_PATH"/"$WUI_NAME"/resources/config.php

# reset network interfaces to defaults
cat << EOF > /etc/network/interfaces

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug eth0
iface eth0 inet dhcp

EOF

/bin/sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-scripts /var/lib/fusionpbx/scripts -rp"',

#Restart Services
for i in nginx php5-fpm fail2ban freeswitch
do /etc/init.d/"${i}" start > /dev/null 2>&1
done
break ;;

*) echo "Answer must be a y/Y or n/N" ;;
esac
done
}

# Factory Reset Postgresql Database
drop_pgsql_db(){
echo "This will drop the current postgresql database table for the pbx."
while : ;do
read -p "Are you sure you wish drop the current pgsql db table? (y/Y/n/N)"
case "$REPLY" in
 n|N) break ;;
 y|Y)

read -r -p "Please enter the postgresql database name you used at install time : " DBNAME
/bin/su -l postgres -c "/bin/echo \"DROP DATABASE $DBNAME;\" | /usr/bin/psql"
break ;;

*) echo "Answer must be a y/Y or n/N" ;;
esac
done
}

# PBX Backup configs/voicemail/personal recordings
backup_pbx(){
echo "This will halt the running services and then "
echo "backup your system to $BACKUPDIR/pbx-backup-$(date +%Y%m%d).tar.bz2"
echo "and then start the services again"
while : ;do
read -p "Are you sure you wish to backup your pbx? (y/Y/n/N)"
case "$REPLY" in
 n|N) break ;;
 y|Y)

# stop system services
for i in monit nginx php5-fpm fail2ban freeswitch
do /etc/init.d/"${i}" stop > /dev/null 2>&1
done

# Backup system (Fusion config.php and database / freeswitch cdr, voicemail, recordings, configs)
tar -cjf "$BACKUPDIR"/"pbx-backup-$(date +%Y%m%d).tar.bz2" "$WWW_PATH"/resources/config.php "$FS_DB"/fusionpbx.db \
	"$FS_LOG"/xml_cdr "$FS_ACT_CONF" "$FS_STOR"

# Restart system services
for i in monit nginx php5-fpm fail2ban freeswitch
do /etc/init.d/"${i}" start > /dev/null 2>&1
done
break ;;

*) echo "Answer must be a y/Y or n/N" ;;
esac
done
}

# Rotate/Clean logs
rotate_logs(){
echo "This will halt the running services and sync the system rotate the logs"
echo "and then restart the services for the pbx system"
while : ;do
read -p "Are you sure you wish to rotate you sysem and freeswitch logs? (y/Y/n/N)"
case "$REPLY" in
 n|N) break ;;
 y|Y)

# stop system services
for i in monit nginx php5-fpm fail2ban freeswitch
do /etc/init.d/"${i}" stop > /dev/null 2>&1
done

rm -f "$FS_LOG"/*.fsxml "$FS_LOG"/*.log

for i in fail2ban inetutils-syslogd
do /etc/init.d/"${i}" start > /dev/null 2>&1
done

/usr/sbin/logrotate -f /etc/logrotate.conf
rm -f /var/log/*.[0-10] /var/log/*.gz

for i in fail2ban inetutils-syslogd
do /etc/init.d/"${i}" stop > /dev/null 2>&1
done

#restart services
for i in nginx php5-fpm fail2ban freeswitch monit
do /etc/init.d/"${i}" start  >/dev/null 2>&1
done
break ;;

*) echo "Answer must be a y/Y or n/N" ;;
esac
done
}

# System Pkg Upgrade
upgrade(){
read -p "Are you sure you wish to update your install (y/Y/n/N) "
if [[ $REPLY =~ ^[Nn]$ ]]
then
return
else
if [[ $REPLY =~ ^[Yy]$ ]]
then
/usr/bin/apt-get update > /dev/null 2>&1 
/usr/bin/apt-get upgrade -y --force-yes
/usr/bin/apt-get autoremove > /dev/null 2>&1
/usr/bin/apt-get clean > /dev/null 2>&1
fi
fi
}

# Restart Freeswitch
fs_restart(){
read -p "Are you sure you wish to restart freeswitch (y/Y/n/N) "
if [[ $REPLY =~ ^[Nn]$ ]]
then
return
else
if [[ $REPLY =~ ^[Yy]$ ]]
then
/etc/init.d/freeswitch restart  >/dev/null 2>&1
fi
fi
}

#Disable Nat Freeswitch
config_nat(){
read -p "Are you sure you wish to enable/disable nat for freeswitch e/E=enable d/D=disable (e/E/d/D) "
if [[ $REPLY =~ ^[Dd]$ ]]
then
/bin/sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-scripts /var/lib/fusionpbx/scripts -rp"',
/bin/echo "init script set to start 'freeswitch -nc -scripts /var/lib/fusionpbx/scripts -rp'"
/etc/init.d/freeswitch restart  >/dev/null 2>&1
else
if [[ $REPLY =~ ^[Ee]$ ]]
then
/bin/sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-scripts /var/lib/fusionpbx/scripts -rp -nonat"',
/bin/echo "init script set to start 'freeswitch -nc -scripts /var/lib/fusionpbx/scripts -rp -nonat'"
/etc/init.d/freeswitch restart  >/dev/null 2>&1
fi
fi
}

# Aminastrator Option Menu
while : ;do
#Clears Screen & Displays System Info
/usr/bin/clear
echo ""
printf 'HostName/DomainName: '; /bin/hostname
printf 'System Uptime: '; /usr/bin/uptime
printf 'System Primary IP: '; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
printf 'System Secondary IP: '; ip -f inet addr show dev eth1 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
#Displays Option Menu
cat << EOF

	PBX Administration Menu:

 *** Setup / Configuration ***
 1) Set/Change Root Password      2) Set Timezone & Time
 3) Setup Network Interface(WAN)  4) Setup Network Interface (LAN)
 5) Setup OpenVPN Connections

  ******** Maintance *********
 6) Web Service Options	      7) Freeswitch CLI       8) Restart Freeswitch
 9) Clear & Rotate logs       10) Backup PBX System   11) Factory Reset System
 12) Drop Postgres Database   13) Reboot System       14) Power Off System
 15) Disable/Enable nat       16) Drop to Shell       x) Logout
     Freeswitch

  ***** Upgrade Options *****
 u) Upgrade

Choice:
EOF

# Aminastrator Option Menu Functions
 read -r ans
 case "$ans" in
  1) set_root_password ;;
  2) set_local_tz ;;
  3) set_net_1 ;;
  4) set_net_2 ;;
  5) set_vpnvpn ;;
  6) web_options ;;
  7) /usr/bin/fs_cli ;;
  8) fs_restart ;;
  9) rotate_logs ;;
  10) backup_pbx ;;
  11) factory_reset ;;
  12) drop pgsql_db ;;
  13) reboot;  kill -HUP "$(pgrep -s 0 -o)" ;;
  14) poweroff; kill -HUP "$(pgrep -s 0 -o)" ;;
  15) config_nat ;;
  16) /bin/bash ;;
  x|X) clear; kill -HUP "$(pgrep -s 0 -o)" ;;
  u|U) upgrade ;;
  *) echo "you must select a valid option (one of: 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,x|X,u|U)" && continue ;;
 esac
done
DELIM

chmod +x /usr/bin/debian.menu

/bin/cat >> "/etc/profile" <<DELIM
/usr/bin/debian.menu
DELIM
fi

#apt-get cleanup
apt-get clean

echo " Install Has Finished...  "