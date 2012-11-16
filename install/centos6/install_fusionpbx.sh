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
#  
#   Also thanks to:
#   The FreeSWITCH, FusionPBX and PostgreSQL Crews without them, none of this would be possible
#  
###############################################
VERSION="0.3"

#get the machine type x86_64
MACHINE_TYPE=`uname -m`

cat <<EOT
This Script will install and create base line configs for FreeSWITCH, FusionPBX, Fail2Ban, Monit and PostgreSQL.
It is designed to run on a Centos6 Minimal Install. EPEL will also be temporarily Enabled to get a few packages
not in the main Centos Repositories.

As with anything you will want to review the configs after the installer to make sure they are what you want.

This is Version $VERSION of this script.

EOT

read -r -p "Are you sure? [Y/n] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "Here we go..."
else
    echo "Aborting"
    exit
fi

# Do a Yum Update to update the system and then install all other required modules 
yum update -y
yum -y install autoconf automake gcc-c++ git-core libjpeg-devel libtool make ncurses-devel pkgconfig unixODBC-devel openssl-devel gnutls-devel libogg-devel libvorbis-devel curl-devel libtiff-devel libjpeg-devel python-devel expat-devel zlib zlib-devel bzip2 which postgresql-devel postgresql-odbc postgresql-server subversion screen vim php* ntp

#lets get the Time Right
ntpdate pool.ntp.org
service ntpd start
chkconfig ntpd on

#Disable SELinux (Ken hates this thing)
if [ -x /usr/sbin/setenforce ]
	then
		setenforce 0
		/bin/sed -i -e s,'SELINUX=enforcing','SELINUX=disabled', /etc/sysconfig/selinux
fi

# Lets go Get the FreeSWITCH Source and install it
cd /usr/src
git clone git://git.freeswitch.org/freeswitch.git
cd freeswitch
./bootstrap.sh -j
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

#Add Settings to freeswitch sysconfig file
cat >> /etc/sysconfig/freeswitch <<EOT
PID_FILE=/var/run/freeswitch/freeswitch.pid
FS_USER=freeswitch
FS_FILE=/usr/local/freeswitch/bin/freeswitch
FS_HOME=/usr/local/freeswitch
EOT

# sym link fs_cli into /usr/local/bin so we don't have to adjust paths
cd /usr/local/bin/
ln -s /usr/local/freeswitch/bin/fs_cli fs_cli

#start installing FusionPBX From Subversion
cd /var/www
svn co http://fusionpbx.googlecode.com/svn/trunk/fusionpbx html

#fix FusionPBX Ownership and Perms
chown -R apache:apache html
cd /usr/local/freeswitch/conf/
chmod 770 `find . -type d`
chmod 660 `find . -type f`

# add apache to the freeswitch Group
usermod -a -G freeswitch apache

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

# start up some services and set them to run at boot
service freeswitch start
service httpd restart
chkconfig freeswitch on
chkconfig httpd on
service monit start
chkconfig monit on

# INIT Postgresql, and set it for easyness
#quick hack to postgresql init script to init the DB with trust access **** YOU MAY NOT WANT THIS FOR PRODUCTION ****
/bin/sed -i -e s,'ident','trust', /etc/init.d/postgresql
service postgresql initdb
service postgresql start
chkconfig postgresql on

#set this back to normal
/bin/sed -i -e s,'trust','ident', /etc/init.d/postgresql

#disable epel repo for normal use. Leaving it enabled canhave unintended consequences
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

#Block 'friendly-scanner' AKA sipvicious
iptables -I INPUT -p udp --dport 5060 -m string --string "friendly-scanner" --algo bm -j DROP
iptables -I INPUT -p udp --dport 5080 -m string --string "friendly-scanner" --algo bm -j DROP

#rate limit registrations to keep us from getting hammered on
iptables -I INPUT -m string --string "REGISTER sip:" --algo bm --to 65 -m hashlimit --hashlimit 4/minute --hashlimit-burst 1 --hashlimit-mode srcip,dstport --hashlimit-name sip_r_limit -j ACCEPT

# FreeSwitch ports internal SIP profile
iptables -I INPUT -p udp -m udp --dport 5060 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 5060 -j ACCEPT

# FreeSwitch Ports external SIP profile
iptables -I INPUT -p udp -m udp --dport 5080 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 5080 -j ACCEPT

# RTP Traffic 16384-32768
iptables -I INPUT -p udp -m udp --dport 16384:32768 -j ACCEPT

# Ports for the Web GUI
iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT

#save the IPTables rules for later
service iptables save


LOCAL_IP=`ifconfig eth0 | head -n2 | tail -n1 | cut -d' ' -f12 | cut -c 6-`
cat <<EOT
As long as you didnt see errors by this point, PostgreSQL, FreeSWITCH, FusionPBX, Fail2Ban, and Monit should in installed.
Point your browser to http://$LOCAL_IP/ and let the FusionPBX installer take it from there.

EOT
