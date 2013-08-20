#!/bin/bash
#Date AUG, 14 2013 18:20 EST
################################################################################
# The MIT License (MIT)
##
# Copyright (c) <2013> <r.neese@gmail.com>
##
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
##
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
##
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
################################################################################

################################################################################
# If you appreciate the work, please consider purchasing something from my
# wishlist. That pays bigger dividends to this coder than anything else I
# can think of ;).
##
# It also keeps development of the script going for more platforms;
##
# Wish list in the works.
##
# 1) odroid-x2 + 1 emmc + ssd adapter + jtag uart. 
# here: http://www.hardkernel.com/renewal_2011/products/prdt_info.php?g_code=G135235611947
##
# 2) Beagle Bone Black + jtag uart. 
# here: http://www.digikey.com/product-detail/en/BB-BBLK-000/BB-BBLK-000-ND/3884456?WT.mc_id=PLA_3884456
##
# 3) Dreamplug + jtag 
# here: http://www.globalscaletechnologies.com/p-54-dreamplug-devkit.aspx
##
# 4) Hackberry + jtag
# here: https://www.miniand.com/products/Hackberry%20A10%20Developer%20Board#buy
################################################################################

################################################################################
echo "This is a 1 time install script. if it fails for any reason please report"
echo "to r.neese@gmail.com . Include any screen output you can to show where it"
echo "fails."
################################################################################

################################################################################
echo "This Script Requires a internet connection "
################################################################################
#check for internet connection. Pulled from and modified
#http://www.linuxscrew.com/2009/04/02/tiny-bash-scripts-check-internet-connection-availability/
wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google &> /dev/null

if [ ! -s /tmp/index.google ];then
	echo "No Internet connection. Please plug in the ethernet cable into eth0"
	exit 1
else
	echo "continuing!"
fi

#<------Start Edit HERE--------->
#Setup up host name or use system default host name or preset host/domain name.
set_host=n

# if you use the set host name please change these to fields.
# Please change this ........
HOST="pbx"
DOMAIN="fusionpbx.com"

#Configure Networking
#IF you machine is at its final install location and needs/requires a static ip
# Change this setting from n to y to enable network setup of eth0.
# Other Wise by default it uses dhcp an the ip will be dynamic wich could lead to issues.
set_net=n

#IF you change set_net=y Please chane these to configure eth0:
#Make shure they match your working network.......
#Wan Interface
IP="0.0.0.0"
#Netmask
NM="255.0.0.0.0"
#Gateway
GW="0.0.0.0"
#Name Servers
NS1="0.0.0.0"
NS2="0.0.0.0"

# set local timezone
# Fresh Installs will require you to set the proper timezone.
# If you have not set your local timezone. Please change n to y
set_tz=n

# Freeswitch Options
freeswitch_install="all" # This is a metapackage which recommends or suggests all packaged FreeSWITCH modules.(Default)
#freeswitch_install="bare" # This is a metapackage which depends on the packages needed for a very bare FreeSWITCH install.
#freeswitch_install="codecs" # This is a metapackage which depends on the packages needed to install most FreeSWITCH codecs.
#freeswitch_install="default" # This is a metapackage which depends on the packages needed for a reasonably basic FreeSWITCH install.
#freeswitch_install="sorbet" # This is a metapackage which recommends most packaged FreeSWITCH modules except a few which aren't recommended.
#freeswitch_install="vanilla" # This is a metapackage which depends on the packages needed for running the FreeSWITCH vanilla example configuration.

#FreeSwitch Configs Options installed in /usr/share/freeswitch/conf/(configname)
#This also copies the default configs into the default active config dir /etc/freeswitch
#freeswitch_conf="curl" # FreeSWITCH curl configuration
#freeswitch_conf="indiseout" # FreeSWITCH insideout configuration
#freeswitch_conf="sbc" # FreeSWITCH session border controller (sbc) configuration
#freeswitch_conf="softphone" # FreeSWITCH softphone configuration
freeswitch_conf="vanilla" # FreeSWITCH vanilla configuration

# to start FreeSWITCH with -nonat option set freeswitch_NAT to y
# Set to y if on public IP
freeswitch_nat=n

#Use fusionpbx Stable debian pkg.
#(Currently the Fusionpkx Stable does not work on wheezy)
# You should use the fusionpbx dev pkg for now
# y=stable branch n=dev branch
fusionpbx_stable=n

#Please Select Server or Client not both.
#Install postgresql Client 9.x for connection to remote pgsql servers (y/n)
pgsql_client=n

#Install postgresql server 9.x (y/n) (client included)(Local Machine)
pgsql_server=n

# ONLY NEEDE IF USING Posgresql Server Localy.
#Please Change the user keeping the name lower case
pgsqluser=pgsqladmin

#Please Change the password keeping it lower case
pgsqlpass=pgsqladmin2013

#Future Options not yet implamented,
#Enable new admin shell menu & openvpn scripts.
enable_admin_menu=n

#<------Stop Edit Here-------->

#Pulled from my own admin menu below.
# Freeswitch logs dir
freeswitch_log="/var/log/freeswitch"
#Freeswitch dflt configs
freeswitch_dflt_conf="/usr/share/freeswitch/conf"
#Freeswitch active config files
freeswitch_act_conf="/etc/freeswitch"

#Nginx
WWW_PATH="/usr/share/nginx/www" #debian nginx default dir
wui_name="fusionpbx"
#Php Conf Files
php_ini="/etc/php5/fpm/php.ini"

#setting Hostname/Domainname
if [ $set_host == "y" ]; then
    HN="$HOST"
    DN="$DOMAIN"
else
    HN=$(hostname)
    DN=$(dnsdomainname)
fi

#setting Hostname/Domainname
cat << EOF > /etc/hostname
$HN.$DN
EOF

# Setup Primary Network Interface
if [[ $set_net == "y" ]]; then
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

#Setup /etc/hosts file
cat << EOF > /etc/hosts
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
$IP     $HN.$DN
$IP     $HN.$DN $DN
EOF
fi

if [[ $set_tz == "y" ]]; then
/usr/sbin/dpkg-reconfigure tzdata
fi

# OS ENVIRONMENT CHECKS
#check for root
if [ $EUID -ne 0 ]; then
   echo "Must Run As Root" 1>&2
   exit 1
fi
echo "You're root."


# Os/Distro Check
lsb_release -c |grep -i wheezy > /dev/null

if [[ $? -eq 0 ]]; then
	DISTRO=wheezy
	echo "Found Debian 7 (wheezy)"
else
	echo "Reqires Debian 7 (Wheezy)"
	exit 1
fi

#Disabling the cd from the /etc/apt/sources.list
sed -i /etc/apt/sources.list -e s,'deb cdrom\:\[Debian GNU/Linux testing _Wheezy_ - Official Snapshot i386 CD Binary-1 20130429-03:58\]/ wheezy main','# deb cdrom\:\[Debian GNU/Linux testing _Wheezy_ - Official Snapshot i386 CD Binary-1 20130429-03:58]\/ wheezy main',

#add curl
apt-get -y install curl

#pulled from freeswitch wiki
#Adding freeswitch repo
/bin/cat > /etc/apt/sources.list.d/freeswitch.list <<DELIM
deb http://files.freeswitch.org/repo/deb/debian/ wheezy main
deb-src http://files.freeswitch.org/repo/deb/debian/ wheezy main
DELIM
#adding key for freeswitch repo
curl http://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add -

#Updating OS and installed pre deps
for i in update upgrade
do apt-get -y "${i}"
done

#------------------
# Installing Freeswitch Deps
#------------------
#install Freeswitch Deps
for i in unzip libjpeg8 libjpeg62 screen htop pkg-config curl libtiff5 libtiff-tools \
		ntp bison autotalent ladspa-sdk tap-plugins swh-plugins libgsm1 libfftw3-3 libpython2.7 \
		libperl5.14 scons libpq5 unixodbc uuid gettext libvlc5 sox flac vim ngrep memcached
do apt-get -y install "${i}"
done

# Freeswitch Install Options.
if [[ $freeswitch_install == "all" ]]; then
	echo " Installing freeswitch all"
	apt-get -y install	freeswitch-meta-all
fi

if [[ $freeswitch_install == "bare" ]]; then
	echo " Installing freeswitch bare"
	apt-get -y install	freeswitch-meta-bare
fi

if [[ $freeswitch_install == "codecs" ]]; then
	echo " Installing freeswitch all codecs"
	apt-get -y install	freeswitch-meta-codecs
fi

if [[ $freeswitch_install == "default" ]]; then
	echo " Installing freeswitch default"
	apt-get -y install	freeswitch-meta-default
fi

if [[ $freeswitch_install == "sorbet" ]]; then
	echo " Installing freeswitch sorbet"
	apt-get -y install	freeswitch-meta-sorbet
fi

if [[ $freeswitch_install == "vanilla" ]]; then
	echo " Installing freeswitch vanilla"
	apt-get -y install	freeswitch-meta-vanilla
fi

#Genertaing /etc/freeswitch config dir.
mkdir $freeswitch_act_conf

#FreeSwitch Configs
if [[ $freeswitch_conf == "curl" ]]; then
	echo " Installing Freeswitch curl configs"
	# Installing defailt configs into /usr/share/freeswitch/conf/(configname).
	apt-get -y install	freeswitch-conf-curl
	#Copy configs into Freeswitch active conf dir.
	cp -rp "$freeswitch_dflt_conf"/curl/* "$freeswitch_act_conf"
	#Chowning files for correct user/group in the active conf dir.
	chown -R freeswitch:freeswitch "$freeswitch_act_conf" 
fi

if [[ $freeswitch_conf == "insideout" ]]; then
	echo " Installing Freeswitch insideout configs"
	apt-get -y install	freeswitch-conf-insideout
	cp -rp "$freeswitch_dflt_conf"/insideoout/* "$freeswitch_act_conf"
	chown -R freeswitch:freeswitch "$freeswitch_act_conf"
fi

if [[ $freeswitch_conf == "sbc" ]]; then
	echo " Installing Freeswitch session border control configs"
	apt-get -y install	freeswitch-conf-sbc
	cp -rp "$freeswitch_dflt_conf"/sbc/* "$freeswitch_act_conf"
	chown -R freeswitch:freeswitch "$freeswitch_act_conf"
fi

if [[ $freeswitch_conf == "softphone" ]]; then
	echo "Installing softphone configs"
	apt-get -y install	freeswitch-conf-softphone
	cp -rp "$freeswitch_dflt_conf"/softphone/* "$freeswitch_act_conf"
	chown -R freeswitch:freeswitch "$freeswitch_act_conf"
fi

if [[ $freeswitch_conf == "vanilla" ]]; then
	echo " Installing Vanilla configs"
	apt-get -y install	freeswitch-conf-vanilla
	cp -rp "$freeswitch_dflt_conf"/vanilla/* "$freeswitch_act_conf"
	chown -R freeswitch:freeswitch "$freeswitch_act_conf"
fi

# Proper file to change init strings in. (/etc/defalut/freeswitch)
# Configuring /etc/default/freeswitch DAEMON_Optional ARGS
sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-rp"',

#remove the default extensions
for i in /etc/freeswitch/directory/default/*.xml ;do rm $i ; done

# SEE http://wiki.freeswitch.org/wiki/Fail2ban
#Fail2ban
for i in fail2ban monit
do apt-get -y install "${i}"
done

#Taken From http://wiki.fusionpbx.com/index.php?title=Monit and edited to work with debian pkgs.
#Adding Monitor to keep freeswitch running.
/bin/cat > /etc/monit/conf.d/freeswitch  <<DELIM
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
/bin/cat > /etc/fail2ban/filter.d/freeswitch.conf  <<DELIM

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

/bin/cat >> /etc/fail2ban/jail.local  <<DELIM
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
/bin/cat > /etc/cron.daily/freeswitch_log_rotation <<DELIM
#!/bin/bash
# logrotate replacement script
# put in /etc/cron.daily
# don't forget to make it executable
# you might consider changing "$freeswitch_act_conf"/autoload_configs/logfile.conf.xml
#  <param name="rollover" value="0"/>

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
for i in fail2ban freeswitch
do /etc/init.d/"${i}" restart  >/dev/null 2>&1
done

#Install and configure  PHP + Nginx + sqlite3
for i in ssl-cert sqlite3 nginx php5-cli php5-sqlite php5-odbc php-db \
	php5-fpm php5-common php5-gd php-pear php5-memcache php-apc
do apt-get -y install "${i}"
done

# Changing file upload size from 2M to 15M
/bin/sed -i $php_ini -e s,"upload_max_filesize = 2M","upload_max_filesize = 15M",

#Nginx config Copied from Debian nginx pkg (nginx on debian wheezy uses sockets by default not ports)
#Install NGINX config file
cat > /etc/nginx/sites-available/fusionpbx  << DELIM
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
for i in nginx php5-fpm
do /etc/init.d/"${i}" restart > /dev/null 2>&1
done

#Adding users to needed groups
adduser www-data freeswitch
adduser freeswitch www-data

#for i in autoload_configs chatplan config.FS0 dialplan directory extensions.conf fur_elise.ttml \
#ivr_menus jingle_profiles lang mime.types mrcp_profiles notify-voicemail.tpl README_IMPORTANT.txt \
#sip_profiles skinny_profiles tetris.ttml voicemail.tpl web-vm.tpl yaml
#do rm -rf /etc/freeswitch/"${i}"
#done

#add fusionpbx wui_name temp Repo until freeswitch gets a repo working for x86)
#dding FusionPBX Web User Interface repo"
/bin/cat > /etc/apt/sources.list.d/fusionpbx.list <<DELIM
deb http://repo.fusionpbx.com wheezy main
deb-src http://repo.fusionpbx.com/ wheezy main
DELIM

apt-get update

# Install fusionpbx Web User Interface
echo "Installing FusionPBX Web User Interface pkg"

if [[ $fusionpbx_stable == "y" ]]; then
	apt-get -y --force-yes install fusionpbx
else
	apt-get -y --force-yes install fusionpbx-dev
fi

#"Re-Configuring /etc/default/freeswitch to use fusionpbx scripts dir"
#DAEMON_Optional ARGS
/bin/sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-scripts /var/lib/fusionpbx/scripts -rp"',

if [ $freeswitch_nat == "y" ]; then
	/bin/sed -i /etc/default/freeswitch -e s,'^DAEMON_OPTS=.*','DAEMON_OPTS="-scripts /var/lib/fusionpbx/scripts -rp -nonat"',
fi

#Clean out the freeswitch conf dir
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

for i in freeswitch nginx php5-fpm
do /etc/init.d/"${i}" restart >/dev/null 2>&1
done

#Pulled From
#http://wiki.fusionpbx.com/index.php?title=Fail2Ban
# Adding fusionpbx to fail2ban
cat > /etc/fail2ban/filter.d/fusionpbx.conf  <<DELIM
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

#Install pgsql-client
if [[ $pgsql_client == "y" ]]; then
	clear
	for i in postgresql-client-9.1 php5-pgsql
	do apt-get -y install "${i}"
	done

	/etc/init.d/php5-fpm restart
	echo
	printf '	Please open a web-browser to http://'; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
cat << DELIM

	Or the Doamin name assigned to the machine like http://mypbx.myip.net.

	On the First configuration page of the web user interface.

	Please Select the PostgreSQL option in the pull-down menu as your Database

	Also Please fill in the SuperUser Name and Password fields.

	On the Second Configuration Page of the web user intercae please fill in the following fields:

	Server: Use the IP or Doamin name assigned to the remote postgresql database server machine
	Port: use the port for the remote pgsql server
	Database Name: "$wui_name"
	Database Username: "$wui_name"
	Database Password: Please Select A Secure Password
	Create Database Username: Database_Superuser_Name of the remote pgsql server
	Create Database Password: Database_Superuser_password of the remote pgsql server

DELIM

fi

#install pgsql-server
if [[ $pgsql_server == "y" ]]; then
	clear
	for i in postgresql-9.1 php5-pgsql
	do apt-get -y install "${i}"
	done

	/etc/init.d/php5-fpm restart

	#Adding a SuperUser and Password for Postgresql database.
	su -l postgres -c "/usr/bin/psql -c \"create role $pgsqluser with superuser login password '$pgsqlpass'\""
	echo
	printf '	Please open a web browser to http://'; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
cat << DELIM

	Or the Doamin name assigned to the machine like http://mypbx.myip.net

	On the First configuration page of the web user interface

	Please Select the PostgreSQL option in the pull-down menu as your Database

	Also Please fill in the SuperUser Name and Password fields.

	On the Second Configuration Page of the web user interface please fill in the following fields:

	Database Name: "$wui_name"
	Database Username: "$wui_name"
	Database Password: Please Select A Secure Password
	Create Database Username: "$pgsqluser"
	Create Database Password: "$pgsqlpass"

DELIM

else

clear
echo
echo
	printf '	Please open a web-browser to http://'; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'

cat << DELIM

	or the Doamin name assigned to the machine like http://mypbx.myip.net.

    on the First Configuration page of the web usre interface "$wui_name".

	also Please fill in the SuperUser Name and Password fields.

    Freeswitch & FusionPBX Web User Interface Installation Completed.

    Now you can configure FreeSWITCH using the FusionPBX web user interface

                         Please reboot your system
DELIM

fi

#cleanup
apt-get clean

# Enable/install shell admin menu
if [[ $enable_admin_menu == "y" ]]; then
/bin/cat > /usr/bin/debian.menu <<DELIM
#!/bin/bash
#Date AUG, 14 2013 18:20 EST 
################################################################################
# The MIT License (MIT)
##
# Copyright (c) <2013> Richard Neese <r.neese@gmail.com>
##
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
##
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
##
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
################################################################################

################################################################################
# If you appreciate the work, please consider purchasing something from my
# wishlist. That pays bigger dividends to this coder than anything else I
# can think of ;).
##
# It also keeps development of the script going for more platforms;
##
# Wish list in the works.
##
# 1) odroid-x2 + 1 emmc + ssd adapter + jtag uart. 
# here: http://www.hardkernel.com/renewal_2011/products/prdt_info.php?g_code=G135235611947
##
# 2) Beagle Bone Black + jtag uart. 
# here: http://www.digikey.com/product-detail/en/BB-BBLK-000/BB-BBLK-000-ND/3884456?WT.mc_id=PLA_3884456
##
# 3) Dreamplug + jtag 
# here: http://www.globalscaletechnologies.com/p-54-dreamplug-devkit.aspx
##
# 4) Hackberry + jtag
# here: https://www.miniand.com/products/Hackberry%20A10%20Developer%20Board#buy
################################################################################

set -eu

#Base Varitables
USRBASE="/usr"
LOCALBASE="/usr/local"
BACKUPDIR="/root/pbx-backup"

# Setup 
HN="$HOST"

WUI_NAME="fusionpbx"

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
WWW_PATH="$USRBASE/share/nginx/www/$WUI_NAME"
#Fusionpbx DB Dir
FPBX_DB="/var/lib/fusionpbx/db"
#FusionPBX Scripts Dir (DialPLan Scripts for use with Freeswitch)
FPBX_SCRPT="/var/lib/fusionpbx/scripts"

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
      dns-search $SD
EOF

cat << EOF > /etc/hosts
127.0.0.1       localhost $HN
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
$IP     $HN.$DN
$IP     $HN.$DN $HN
EOF

cat << EOF > /etc/hostname
$HN.$DN
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
/usr/local/bin/confgen
done
}

# Factory Reset System
factory_reset(){
while : ;do
read -p "Are you sure you wish to factory reset you pbx? (y/Y/n/N)"
case $REPLY in
 n|N) break ;;
 y|Y)
# stop system services
for i in nginx php5-fpm fail2ban freeswitch
do /etc/init.d/"${i}" stop  >/dev/null 2>&1
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

if exists "$FBPX_DB"/fusionpbx.db rm -f "$FBPX_DB"/fusionpbx.db

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

# Factory Reset System
drop_pgsql_db(){
while : ;do
read -p "Are you sure you wish drop the current pgsql db table? (y/Y/n/N)"
case $REPLY in
 n|N) break ;;
 y|Y)
do /bin/su -l postgres -c "/bin/echo \"DROP DATABASE $WUI_NAME;\" | /usr/bin/psql"
done
}

# PBX Backup configs/voicemail/personal recordings
backup_pbx(){
read "This will halt the running services and then "
read "backup your system to $BACKUPDIR/pbx-backup-$(date +%Y%m%d).tar.bz2"
read "and then start the services again"
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
tar -cjf "$BACKUPDIR"/pbx-backup-$(date +%Y%m%d).tar.bz2 "$WWW_PATH"/resources/config.php "$FS_DB"/fusionpbx.db \
	"$FS_LOG"/xml_cdr "$FS_ACT_CONF" "$FS_STOR"

# Restart system services
for i in monit nginx php5-fpm fail2ban freeswitch
do /etc/init.d/"${i}" start > /dev/null 2>&1
done

;;
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

for i in monit nginx php5-fpm fail2ban freeswitch
do /etc/init.d/"${i}" stop  >/dev/null 2>&1 
done
rm -f "$FS_LOG"/*.log
rm -f "$FS_LOG"/*.fsxml
/etc/init.d/fail2ban start > /dev/null 2>&1
/etc/init.d/inetutils-syslogd start > /dev/null 2>&1
/usr/sbin/logrotate -f /etc/logrotate.conf
rm -f /var/log/*.0 /var/log/*.1 /var/log/*.2 /var/log/*.3 /var/log/*.4 \
	/var/log/*.5 /var/log/*.6 /var/log/*.7 /var/log/*.8 /var/log/*.9 \
	/var/log/*.10  /var/log/*.gz
/etc/init.d/fail2ban stop > /dev/null 2>&1
/etc/init.d/inetutils-syslogd stop > /dev/null 2>&1
for i in monit nginx php5-fpm fail2ban freeswitch
do /etc/init.d/"${i}" start  >/dev/null 2>&1
done
break
;;
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
/usr/bin/apt-get update > /dev/null && \
/usr/bin/apt-get upgrade && \
/usr/bin/apt-get autoremove && \
/usr/bin/apt-get clean 
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
/bin/echo "init script set to start 'freeswitch -nc -scripts /var/lib/fusionpbx/scripts -rp -nonat'"
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
 5) Setup OpenVPN Connections (Future Option)    

  ******** Maintance *********
 6) Web Service Options	   7) Freeswitch CLI       8) Restart Freeswitch
 9) Clear & Rotate logs    10) Backup PBX System   11) Factory Reset System
 12) Drop PGSQL Database   13) Reboot System       14) Power Off System    
 14) Disable/Enable nat freeswitch  15) Drop to Shell         x) Logout

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
  13) reboot;  kill -HUP $(pgrep -s 0 -o) ;;
  14) poweroff; kill -HUP $(pgrep -s 0 -o) ;;
  15) config_nat ;;
  16) /bin/bash ;;
  x|X) clear; kill -HUP $(pgrep -s 0 -o) ;;
  u|U) upgrade ;;
  *) echo "you must select a valid option (one of: 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,x|X,u|U)" && continue ;;
 esac
done
DELIM

#confgen
/bin/cat > /usr/bin/confgen <<DELIM
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
/bin/cat > /usr/bin/genclient.sh <<DELIM
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
/bin/cat > /usr/bin/genserver.sh <<DELIM
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

for i in debian.menu confgen genclient.sh genserver.sh
do chmod +x /usr/bin/${i}
done

fi
