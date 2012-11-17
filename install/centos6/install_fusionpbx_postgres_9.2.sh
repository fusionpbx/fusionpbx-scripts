#!/bin/bash

###############################################
#
#   Installation Script to Install FreeSWITCH, FusionPBX, PostgreSQL, PHP, Apache and required
#   Supporting software on Centos 6.
#   Copyright (C) 2011, Ken Rice <krice@tollfreegateway.com>
#  
#   Version: MPL 1.1
#  
#   The contents of this file are subject to the Mozilla Public License Version
#   1.1 (the "License"); you may not use this file except in compliance with
#   the License. You may obtain a copy of the License at
#   http://www.mozilla.org/MPL/
#  
#   Software distributed under the License is distributed on an "AS IS" basis,
#   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
#   for the specific language governing rights and limitations under the
#   License.
#  
#   The Initial Developer of the Original Code is
#   Ken Rice <krice@tollfreegateway.com>
#   Portions created by the Initial Developer are Copyright (C)
#   the Initial Developer. All Rights Reserved.
#  
#   Contributor(s):
#   
#   Ken Rice <krice@tollfreegateway.com>
#   Dar Zuch <support@helia.ca>
#   Mark J Crane <mark@fusionpbx.com>
#   Also thanks to:
#   The FreeSWITCH, FusionPBX and PostgreSQL Crews without them, none of this would be possible
#  
###############################################
VERSION="0.9"

###########################################
##  Set Defaults for Variables

defSUPPORTNAME='Company Name'
defSUPPORTEMAIL='support@example.com'
defPUBLICHOSTNAME='voice.example.com'
defDOMAINNAME='example.com'

###########################################

#get the machine type x86_64
MACHINE_TYPE=`uname -m`


cat <<EOT

This Script will install and create base line configs for FreeSWITCH, FusionPBX, Fail2Ban, Monit and PostgreSQL, TLS.
It is designed to run on a Centos6.2 I386/x86_64 "Basic Server" Install. EPEL will also be temporarily Enabled to get a few packages
not in the main Centos Repositories.

As with anything you will want to review the configs after the installer to make sure they are what you want.

This is Version $VERSION of this script.

EOT

read -p "SNMP Support Name [$defSUPPORTNAME]: " -e t1
if [ -n "$t1" ]
then
SUPPORTNAME="$t1"
else
SUPPORTNAME="$defSUPPORTNAME"
fi


read -p "Support Email [$defSUPPORTEMAIL]: " -e t1
if [ -n "$t1" ]
then
SUPPORTEMAIL="$t1"
else
SUPPORTEMAIL="$defSUPPORTEMAIL"
fi

read -p "Domain Name [$defDOMAINNAME]: " -e t1
if [ -n "$t1" ]
then
DOMAINNAME="$t1"
else
DOMAINNAME="$defDOMAINNAME"
fi

defPUBLICHOSTNAME='voice.${DOMAINNAME}'

read -p "Public Hostname [$defPUBLICHOSTNAME]: " -e t1
if [ -n "$t1" ]
then
PUBLICHOSTNAME="$t1"
else
PUBLICHOSTNAME="$defPUBLICHOSTNAME"
fi

read -r -p "Are you sure? [Y/n] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
echo "Here we go..."
else
echo "Aborting"
exit
fi


###########################################3
#dz  Install OpenSSL for TLS and SRTP support
yum -y install openssl-devel


###############

#dz  Install SNMP to support mod_snmp
#dz  net-snmp-devel necessary to install net-snmp-config script
yum -y install net-snmp net-snmp-utils net-snmp-devel

mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.org

#Create a new config file.

#Add Settings to freeswitch sysconfig filed
cat >> /etc/snmp/snmpd.conf <<EOT
rocommunity  public
syslocation  ${SUPPORTNAME}
syscontact  ${SUPPORTEMAIL}
EOT

#Start the snmpd service

/etc/init.d/snmpd start

# snmpwalk -v 1 -c public -O e 127.0.0.1


chkconfig snmpd on

#################

# dz move to directory that is more open so that when we su, its not restricted.
cd /usr/local/src
mkdir fusionpbxinstall
cd fusionpbxinstall


# dz add the postgresql 9.2 repository so it can be installed via yum
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
  wget http://yum.pgrpms.org/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-6.noarch.rpm
else
  wget http://yum.pgrpms.org/9.2/redhat/rhel-6-i386/pgdg-centos92-9.2-6.noarch.rpm
fi
rpm -ivh pgdg-centos92-9.2-6.noarch.rpm

# Do a Yum Update to update the system and then install all other required modules
yum update -y
yum -y install autoconf automake gcc-c++ git-core libjpeg-devel libtool make ncurses-devel pkgconfig unixODBC-devel openssl-devel gnutls-devel libogg-devel libvorbis-devel curl-devel libtiff-devel libjpeg-devel python-devel expat-devel zlib zlib-devel bzip2 which postgresql92-devel postgresql92-odbc postgresql92-server subversion screen vim php* ntp


# dz Install unixodbc so we can switch from the default sqllite db to postgresql for Freeswitch
yum -y install unixODBC-devel postgresql-odbc

# dz this has not been tested.
cat >> /etc/odbc.ini << EOT
[freeswitch]
; WARNING: The old psql odbc driver psqlodbc.so is now renamed psqlodbcw.so
; in version 08.x. Note that the library can also be installed under an other
; path than /usr/local/lib/ following your installation.
Driver = /usr/lib/psqlodbcw.so
Description=Connection to LDAP/POSTGRESQL
Servername=127.0.0.1
Port=5432
;Protocol=6.4  #dz does this need to be 9.1 for postgresql 9.1?
FetchBufferSize=99
Username=freeswitch
;Password=password
Database=freeswitch
ReadOnly=no
Debug=1
CommLog=1

[fusionpbx]
Driver = /usr/lib/psqlodbcw.so
Description=Connection to FusionPBX used for mod_CDR
Servername=127.0.0.1
Port=5432
;Protocol=6.4  #dz does this need to be 9.1 for postgresql 9.1?
FetchBufferSize=99
Username=fusionpbx
;Password=password
Database=fusionpbx
ReadOnly=no
Debug=1
CommLog=1
EOT

#users for Postgres are added after Postgres is started

#lets get the Time Right
ntpdate pool.ntp.org
service ntpd start
chkconfig ntpd on

#Disable SELinux
if [ -x /usr/sbin/setenforce ]
	then
		/usr/sbin/setenforce 0
		/bin/sed -i -e s,'SELINUX=enforcing','SELINUX=disabled', /etc/sysconfig/selinux
#dz it seems both these files exist on Centos 6.2 but this next on actually controls selinux
        /bin/sed -i -e s,'SELINUX=enforcing','SELINUX=disabled', /etc/selinux/config
fi

# Lets go Get the FreeSWITCH Source and install it
cd /usr/src
git clone git://git.freeswitch.org/freeswitch.git
cd freeswitch
git checkout v1.2.stable
./bootstrap.sh -j

#dz modify the /usr/src/freeswitch/modules.conf file here  dz120308
/bin/sed -i -e s,'#applications/mod_callcenter','applications/mod_callcenter', /usr/src/freeswitch/modules.conf
/bin/sed -i -e s,'#endpoints/mod_rtmp','endpoints/mod_rtmp', /usr/src/freeswitch/modules.conf
/bin/sed -i -e s,'#endpoints/mod_dingaling','endpoints/mod_dingaling', /usr/src/freeswitch/modules.conf
/bin/sed -i -e s,'#applications/mod_lcr','applications/mod_lcr', /usr/src/freeswitch/modules.conf
/bin/sed -i -e s,'#applications/mod_blacklist','applications/mod_blacklist', /usr/src/freeswitch/modules.conf
#mod_cidlookup requires additional configuration which is not yet in this script
/bin/sed -i -e s,'#applications/mod_cidlookup','applications/mod_cidlookup', /usr/src/freeswitch/modules.conf
#/bin/sed -i -e s,'#asr_tts/mod_pocketsphinx','asr_tts/mod_pocketsphinx', /usr/src/freeswitch/modules.conf
/bin/sed -i -e s,'#applications/mod_voicemail_ivr','applications/mod_voicemail_ivr', /usr/src/freeswitch/modules.conf

/bin/sed -i -e s,'#event_handlers/mod_snmp','event_handlers/mod_snmp', /usr/src/freeswitch/modules.conf
/bin/sed -i -e s,'#formats/mod_shout','formats/mod_shout', /usr/src/freeswitch/modules.conf
/bin/sed -i -e s,'#asr_tts/mod_tts_commandline','asr_tts/mod_tts_commandline', /usr/src/freeswitch/modules.conf
/bin/sed -i -e s,'#asr_tts/mod_flite','asr_ttsmod_flite', /usr/src/freeswitch/modules.conf

./configure --without-libcurl -C
make -j `cat /proc/cpuinfo |grep processor |wc -l`
make install
make cd-moh-install && make cd-sounds-install
#add a user for freeswitch
useradd freeswitch

#set ownership, perms, and install init scripts
cd /usr/local/
chown -R freeswitch:freeswitch freeswitch
chmod -R g+w freeswitch
cd /usr/src/freeswitch/build
cp freeswitch.init.redhat /etc/init.d/freeswitch
chmod +x /etc/init.d/freeswitch
cp freeswitch.sysconfig /etc/sysconfig/freeswitch

#Add Settings to freeswitch sysconfig filed
cat >> /etc/sysconfig/freeswitch <<EOT
PID_FILE=/var/run/freeswitch/freeswitch.pid
FS_USER=freeswitch
FS_FILE=/usr/local/freeswitch/bin/freeswitch
FS_HOME=/usr/local/freeswitch
EOT

configure mod_cidlookup
#dz need to install UnixODBC first
# see http://wiki.freeswitch.org/wiki/Using_ODBC_in_the_core

mv /usr/local/freeswitch/conf/autoload_configs/cidlookup.conf.xml /usr/local/freeswitch/conf/autoload_configs/cidlookup.conf.xml.bak
cat >> /usr/local/freeswitch/conf/autoload_configs/cidlookup.conf.xml <<EOT
<configuration name="cidlookup.conf" description="cidlookup Configuration">
<settings>
<param name="cache" value="true"/>
<param name="cache-expire" value="86400"/>
<param name="odbc-dsn" value="fusionpbx:fusionpbx:"/>
<param name="sql" value="
SELECT  p.contact_name_family ||', '|| p.contact_name_given as name
FROM v_contact_phones n INNER JOIN v_contacts p ON n.contact_uuid = p.contact_uuid
WHERE n.phone_number = '${caller_id_number}'
LIMIT 1
"/>
</settings>
</configuration>
EOT

/bin/sed -i -e s,'<!-- <param name="core-db-dsn" value="dsn:username:password" /> -->','<param name="core-db-dsn" value="freeswitch:freeswitch:" />', /usr/local/freeswitch/conf/autoload_configs/switch.conf.xml

chown  apache:apache /usr/local/freeswitch/conf/autoload_configs/cidlookup.conf.xml

#dz Change Sofia to use Postgres
/bin/sed -i -e s,'</settings>','<param name="odbc-dsn" value="freeswitch:freeswitch:"/></settings>', /usr/local/freeswitch/conf/sip_profiles/internal.xml
/bin/sed -i -e s,'</settings>','<param name="odbc-dsn" value="freeswitch:freeswitch:"/></settings>', /usr/local/freeswitch/conf/sip_profiles/external.xml

#dz Use Postgres for voicemail
/bin/sed -i -e s,'<!--<param name="odbc-dsn" value="dsn:user:pass"/>-->','<param name="odbc-dsn" value="freeswitch:freeswitch:"/>', /usr/local/freeswitch/conf/autoload_configs/voicemail.conf.xml


# sym link fs_cli into /usr/local/bin so we don't have to adjust paths
cd /usr/local/bin/
ln -s /usr/local/freeswitch/bin/fs_cli fs_cli

#start installing FusionPBX From Subversion
#cd /var/www
#svn co http://fusionpbx.googlecode.com/svn/trunk/fusionpbx html

cd /var/www/html

mkdir fusionpbx
svn co http://fusionpbx.googlecode.com/svn/trunk/fusionpbx fusionpbx

#Add a redirect so the default doc at the web root goes to the fusionpbx login.
cat > /var/www/html/index.php <<EOT
<?php header( 'Location: /fusionpbx/index.php' ) ;?>
EOT

#fix FusionPBX Ownership and Perms
#chown -R apache:apache html
chown -R apache:apache fusionpbx

cd /usr/local/freeswitch/conf/
chmod 770 `find . -type d`
chmod 660 `find . -type f`

# add apache to the freeswitch Group
usermod -a -G freeswitch apache

# dz20120614  Freeswitch should be in the apache group.  Freeswitch is a
#    more critical service and apache is more public.  Therefore we should
#   not allow apache access to the freeswitch files.  Conf files that
#   are modified by the web interface should be owned by the apache group
#   and freeswitch should have access to it.

# add freeswitch to the apache group
usermod -a -G apache freeswitch

## Install EPEL so we can get monit and ngrep
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
	rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-7.noarch.rpm
else
	rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-7.noarch.rpm
fi

#Install Monit, Fail2Ban, and ngrep
yum install -y monit ngrep fail2ban

#Drop monit configs in the right spot
cat > /etc/monit.d/freeswitch <<EOT
 check process freeswitch with pidfile /usr/local/freeswitch/run/freeswitch.pid
   group voice
   start program = "/etc/init.d/freeswitch start"
   stop  program = "/etc/init.d/freeswitch stop"
   if failed port 5060 type UDP then restart
   if 5 restarts within 5 cycles then timeout
   depends on freeswitch_bin
   depends on freeswitch_rc

 check file freeswitch_bin with path /usr/local/freeswitch/bin/freeswitch
   group voice
   if failed checksum then unmonitor
   if failed permission 755 then unmonitor
   if failed uid freeswitch then unmonitor

 check file freeswitch_rc with path /etc/init.d/freeswitch
   group voice
   if failed checksum then unmonitor
   if failed permission 755 then unmonitor
   if failed uid root then unmonitor
   if failed gid root then unmonitor

EOT

#Add Fail2Ban configs for
echo > /etc/fail2ban/filter.d/freeswitch.conf << EOT
# Fail2Ban configuration file
#
# Author: Rupa SChomaker
#

[Definition]

# Option:  failregex
# Notes.:  regex to match the password failures messages in the logfile. The
#          host must be matched by a group named "host". The tag "<HOST>" can
#          be used for standard IP/hostname matching and is only an alias for
#          (?:::f{4,6}:)?(?P<host>[\w\-.^_]+)
# Values:  TEXT
#
failregex = \[WARNING\] sofia_reg.c:\d+ SIP auth failure \(REGISTER\) on sofia profile \'\S+\' for \[.*\] from ip <HOST>
            \[WARNING\] sofia_reg.c:\d+ SIP auth failure \(INVITE\) on sofia profile \'\S+\' for \[.*\] from ip <HOST>

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOT

echo >> /etc/fail2ban/jail.conf << EOT
[freeswitch-tcp]

enabled  = true
port     = 5060,5061,5080,5081
protocol = tcp
filter   = freeswitch
logpath  = /usr/local/freeswitch/log/freeswitch.log
action   = iptables-allports[name=freeswitch-tcp, protocol=all]
           sendmail-whois[name=FreeSwitch, dest=root, sender=fail2ban@example.org]

[freeswitch-udp]

enabled  = true
port     = 5060,5061,5080,5081
protocol = udp
filter   = freeswitch
logpath  = /usr/local/freeswitch/log/freeswitch.log
action   = iptables-allports[name=freeswitch-udp, protocol=all]
           sendmail-whois[name=FreeSwitch, dest=root, sender=fail2ban@example.org]
EOT

echo > /etc/fail2ban/filter.d/fusionpbx.conf << EOT
# Fail2Ban configuration file
#
# Author: soapee01
#

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
failregex = .* FusionPBX: \[<HOST>\] authentication failed for
          = .* FusionPBX: \[<HOST>\] provision attempt bad password for

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
EOT

echo >> /etc/fail2ban/jail.conf << EOT
[fusionpbx]

enabled  = true
port     = 80,443
protocol = tcp
filter   = fusionpbx
logpath  = /var/log/messages
action   = iptables-allports[name=fusionpbx, protocol=all]
           sendmail-whois[name=FusionPBX, dest=root, sender=fail2ban@example.org]

EOT


# INIT Postgresql, and set it for easyness
#quick hack to postgresql init script to init the DB with trust access **** YOU MAY NOT WANT THIS FOR PRODUCTION ****
 /bin/sed -i -e s,'ident','trust', /etc/init.d/postgresql-9.2
cd /etc/init.d/
./postgresql-9.2 initdb
chkconfig postgresql-9.2 on
service postgresql-9.2 start

#set this back to normal
/bin/sed -i -e s,'trust','ident', /etc/init.d/postgresql-9.2
service postgresql-9.2 restart

#create users for core Freeswitch
cd /var/tmp
sudo -u postgres /usr/pgsql-9.2/bin/createuser -s -e freeswitch
sudo -u postgres /usr/pgsql-9.2/bin/createdb -E UTF8 -O freeswitch freeswitch

# dz create a fusionpbx user and a fusionpbx database.
cd /var/tmp
sudo -u postgres /usr/pgsql-9.2/bin/createuser -s -e fusionpbx
sudo -u postgres /usr/pgsql-9.2/bin/createdb -E UTF8 -O fusionpbx fusionpbx

# dz create a script to do a backup of the postgre databases (to disk).  Assuming you have another
# script that backs the freeswitch and fusionpbx folder up
wget -P /usr/local/freeswitch/scripts/ http://helia.ca/a/fusionpbx/pb_backup_rotated.sh
chmod 755 /usr/local/freeswitch/scripts/pb_backup_rotated.sh

# dz  Create a cron job to backup the postgres dbs to disk every day at 5 minutes past midnight
cat >> /var/spool/cron/root << EOT
5 0 * * * /usr/local/freeswitch/scripts/pb_backup_rotated.sh
EOT

#disable epel repo for normal use. Leaving it enabled can have unintended consequences
/bin/sed -i -e s,'enabled=1','enabled=0', /etc/yum.repos.d/epel.repo

#Make the Prompt Pretty and add a few aliases that come in handy
cat >>~/.bashrc <<EOT
export LESSCHARSET="latin1"
export LESS="-R"
export CHARSET="ISO-8859-1"
export PS1='\n\[\033[01;31m\]\u@\h\[\033[01;36m\] [\d \@] \[\033[01;33m\] \w\n\[\033[00m\]<\#>:'
export PS2="\[\033[1m\]> \[\033[0m\]"
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig
export VISUAL=vim

umask 022
alias vi='vim'
alias fstop='top -p \`cat /usr/local/freeswitch/run/freeswitch.pid\`'
alias fsgdb='gdb /usr/local/freeswitch/bin/freeswitch \`cat /usr/local/freeswitch/run/freeswitch.pid\`'
alias fscore='gdb /usr/local/freeswitch/bin/freeswitch \`ls -rt core.* | tail -n1\`'
EOT

#Add a screenrc with a status line, a big scroll back and ^\ as the metakey as to not screw with emacs users
cat >> ~/.screenrc <<EOT
hardstatus alwaysignore
startup_message off
escape ^\b
defscrollback 8000

# status line at the bottom
hardstatus on
hardstatus alwayslastline
hardstatus string "%{.bW}%-w%{.rW}%f%n %t%{-}%+w %=%{..G}[%H %l] %{..Y} %m/%d %c "

termcapinfo xterm \'is=\E[r\E[m\E[2J\E[H\E[?7h\E[?1;4;6l\'
EOT

# and finally lets fix up IPTables so things works correctly

# SSH port
iptables -I INPUT -p tcp -m tcp --dport 22 -j ACCEPT

# Block 'friendly-scanner' AKA sipvicious
iptables -I INPUT -p udp --dport 5060 -m string --string "friendly-scanner" --algo bm -j DROP
iptables -I INPUT -p udp --dport 5080 -m string --string "friendly-scanner" --algo bm -j DROP

# rate limit registrations to keep us from getting hammered on
iptables -I INPUT -m string --string "REGISTER sip:" --algo bm --to 65 -m hashlimit --hashlimit 4/minute --hashlimit-burst 1 --hashlimit-mode srcip,dstport --hashlimit-name sip_r_limit -j ACCEPT

# FreeSwitch ports internal SIP profile
iptables -I INPUT -p udp -m udp --dport 5060 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 5060 -j ACCEPT

# FreeSwitch Ports external SIP profile
iptables -I INPUT -p udp -m udp --dport 5080 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 5080 -j ACCEPT

# NTP time port for phones
iptables -I INPUT -p udp -m udp --dport 123 -j ACCEPT

# FreeSwitch ports internal SIPS profile
iptables -I INPUT -p tcp -m tcp --dport 5061 -j ACCEPT

# FreeSwitch ports external SIPS profile
iptables -I INPUT -p tcp -m tcp --dport 5081 -j ACCEPT

# RTP Traffic 16384-32768
iptables -I INPUT -p udp -m udp --dport 16384:32768 -j ACCEPT

# Ports for the Web GUI
iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT

# Ports for SNMP
iptables -I INPUT -p udp -m udp --dport 161 -j ACCEPT
iptables -I INPUT -p udp -m udp --dport 162 -j ACCEPT

#save the IPTables rules for later
service iptables save

#################################
#generate cert for TLS
#NOTE: the domain name here
/usr/local/freeswitch/bin/gentls_cert setup -cn ${PUBLICHOSTNAME} -alt DNS:${PUBLICHOSTNAME} -org ${DOMAINNAME}
# Creates file cafile.pem and CA/cacert.pem, CA/cakey.pem, CA/config.tpl

cat <<EOT

******************************

Almost done!   Now certificates for encryption of TLS and SRTP will be created.  Answer yes when asked to create the certificates.

******************************

EOT

/usr/local/freeswitch/bin/gentls_cert create_server -cn ${PUBLICHOSTNAME} -alt DNS:${PUBLICHOSTNAME} -org ${DOMAINNAME}
# Creates file agent.pem CA/cacert.srl

#review the cert
#openssl x509 -noout -inform pem -text -in /usr/local/freeswitch/conf/ssl/agent.pem

chown freeswitch:freeswitch /usr/local/freeswitch/conf/ssl/agent.pem
#chown freeswitch:freeswitch /usr/local/freeswitch/conf/ssl/cacert.pem  # This file is the orig but doesn't exist
chown freeswitch:freeswitch /usr/local/freeswitch/conf/ssl/CA/cacert.pem  # right file name in a CA folder
chown freeswitch:freeswitch /usr/local/freeswitch/conf/ssl/cafile.pem	# file name is wrong


chmod 640 /usr/local/freeswitch/conf/ssl/agent.pem
#chmod 640 /usr/local/freeswitch/conf/ssl/cacert.pem	# This file is the orig but doesn't exist
chmod 640 /usr/local/freeswitch/conf/ssl/CA/cacert.pem	# right filename in the CA folder
# file name is wrong
chmod 640 /usr/local/freeswitch/conf/ssl/cafile.pem


/bin/sed -i -e s,'<X-PRE-PROCESS cmd="set" data="external_ssl_enable=false"/>','<X-PRE-PROCESS cmd="set" data="external_ssl_enable=true"/>', /usr/local/freeswitch/conf/vars.xml
/bin/sed -i -e s,'<X-PRE-PROCESS cmd="set" data="internal_ssl_enable=false"/>','<X-PRE-PROCESS cmd="set" data="internal_ssl_enable=true"/>', /usr/local/freeswitch/conf/vars.xml

# Generate client certificate
/usr/local/freeswitch/bin/gentls_cert create_client -cn client.${DOMAINNAME} -out phone


#######################################################


# start up some services and set them to run at boot
service freeswitch start
service httpd restart
chkconfig freeswitch on
chkconfig httpd on
service monit start
chkconfig monit on


LOCAL_IP=`ifconfig eth0 | head -n2 | tail -n1 | cut -d' ' -f12 | cut -c 6-`

cat <<EOT
As long as you didnt see errors by this point, PostgreSQL, FreeSWITCH, FusionPBX, Fail2Ban, and Monit should be installed.
Point your browser to http://$LOCAL_IP/ and let the FusionPBX installer take it from there.

EOT
