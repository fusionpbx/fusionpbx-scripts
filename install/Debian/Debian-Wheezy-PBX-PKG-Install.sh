#!/bin/bash
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
#Enable new admin shell menu
#enable_admin_menu=y

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
/bin/hostname $HN.$DN

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


