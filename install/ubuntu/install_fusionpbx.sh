#!/bin/bash

# install_fusionpbx

LICENSE=$( cat << DELIM
#------------------------------------------------------------------------------
#
# "THE WAF LICENSE" (version 1)
# This is the Wife Acceptance Factor (WAF) License.  
# jamesdotfsatstubbornrosesd0tcom  wrote this file.  As long as you retain this
# notice you can do whatever you want with it. If you appreciate the work,
# please consider purchasing something from my wife's wishlist. That pays
# bigger dividends to this coder than anything else I can think of ;).  It also
# keeps her happy while she's being ignored; so I can work on this stuff.
#   James Rose
#
# latest wishlist: http://www.stubbornroses.com/waf.html
#
# Credit: Based off of the BEER-WARE LICENSE (REVISION 42) by Poul-Henning Kamp
#
#------------------------------------------------------------------------------
DELIM
)

#---------
#VARIABLES
#---------
#Variables are for the auto installation option.

#for apache set to a, for nginx/php-fpm set to n -> for an auto install, user mode will prompt
APACHENGINX=n

# for mysql set m. for sqlite set s. for postgresql set p
SQLITEMYSQL=s

# for postgresql v 9.0 (from ppa) set to 9, otherwise stick with 8
# must set SQLITEMYSQL to p
POSTGRES9=9

# to start FreeSWITCH with -nonat option set SETNONAT to y
SETNONAT=n

# rm -Rf /opt? A default install doesn't have /opt so no worries
# if you do, set to no, and it will link /usr/local/freeswitch to /opt/freeswitch
#REMOVED OPTION
#RMOPT=y

# use freedtm/dahdi? y/n
DO_DAHDI=n

# default distro
DISTRO=precise
#DISTRO=squeeze
#DISTRO=precise
#DISTRO=lucid

#below is a list of modules we want to add to provide functionality for FusionPBX
#don't worry about the applications/mod_ format.  This script will find that in modules.conf
#PAY ATTENTION TO THE SPACES POST AND PRE PARENTHESIS
#  mod_shout removed
if [ $DO_DAHDI == "y" ]; then
	modules_add=( ../../libs/freetdm/mod_freetdm mod_spandsp mod_dingaling mod_portaudio mod_callcenter mod_lcr mod_cidlookup mod_directory mod_flite mod_memcache, mod_codec2 mod_pocketsphinx mod_xml_cdr mod_say_es )
else
	modules_add=( mod_spandsp mod_dingaling mod_callcenter mod_lcr mod_cidlookup mod_directory mod_memcache, mod_codec2 mod_pocketsphinx mod_xml_cdr mod_say_es )
fi

#-------
#DEFINES
#-------
VERSION="Version - using subversion, no longer keeping track. WAF License"
# Modules_comp_default determined using
#  grep -v ^$ /usr/src/freeswitch/modules.conf |grep -v ^# | tr '\n' ' '
#  on FreeSWITCH version FreeSWITCH Version 1.0.head (git-8f2ee97 2010-12-05 17-19-28 -0600)
#modules_comp_default=( loggers/mod_console loggers/mod_logfile loggers/mod_syslog applications/mod_commands applications/mod_conference applications/mod_dptools applications/mod_enum applications/mod_fifo applications/mod_db applications/mod_hash applications/mod_voicemail applications/mod_expr applications/mod_esf applications/mod_fsv applications/mod_spandsp applications/mod_cluechoo applications/mod_valet_parking codecs/mod_g723_1 codecs/mod_amr codecs/mod_g729 codecs/mod_h26x codecs/mod_bv codecs/mod_ilbc codecs/mod_speex codecs/mod_siren dialplans/mod_dialplan_xml dialplans/mod_dialplan_asterisk endpoints/mod_sofia endpoints/mod_loopback event_handlers/mod_event_socket event_handlers/mod_cdr_csv formats/mod_native_file formats/mod_sndfile formats/mod_local_stream formats/mod_tone_stream formats/mod_file_string languages/mod_spidermonkey languages/mod_lua say/mod_say_en say/mod_say_ru )
#making dynamic
#MOVING: Needs to happen after bootstrap...
#modules_comp_default=( `/bin/grep -v ^$ /usr/src/freeswitch/modules.conf |/bin/grep -v ^# | /usr/bin/tr '\n' ' '` )

#staying with default repository, feel free to change this to github. Some report faster downloads.
FSGIT=git://git.freeswitch.org/freeswitch.git
#FSGIT=git://github.com/FreeSWITCH/FreeSWITCH.git
FSSTABLE=true
FSStableVer="v1.2.stable"

#right now, make -j not working. see: jira FS-3005
#CORES=$(/bin/grep processor -c /proc/cpuinfo)
CORES=1
FQDN=$(hostname -f)
#SRCPATH="/usr/src/freeswitch" #DEFAULT
SRCPATH="/usr/src/freeswitch"
#EN_PATH="/usr/local/freeswitch/conf/autoload_configs" #DEFAULT
EN_PATH="/usr/local/freeswitch/conf/autoload_configs"
WWW_PATH="/var/www"
GUI_NAME=fusionpbx
INST_FPBX=svn
#INST_FPBX=tgz
#full path required
#TGZ_FILE="/home/coltpbx/fusionpbx-1.2.1.tar.gz"
FSREV="187abe02af4d64cdedc598bd3dfb1cd3ed0f4a91"
FSCHECKOUTVER=false
FPBXREV="1876"
FBPXCHECKOUTVER=false
URLSCRIPT="http://fusionpbx.googlecode.com/svn/branches/dev/scripts/install/ubuntu/install_fusionpbx.sh"
INSFUSION=0
INSFREESWITCH=0
UPGFUSION=0
UPGFREESWITCH=0

#---------
#  NOTES
#---------
# This Script installs or upgrades FreeSWITCH and FusionPBX on a fresh install of 
# Ubuntu 10.04 LTS [lucid].  It tries to edit all appropriate files, and
# set the permissions correctly.

#When you install ubuntu, you should select the "Manual package selection" option.  
#This way we can keep the install to the bare minimum.  This script will install
#everything you need (and nothing) - hopefully, you don't. Just quit tasksel

#---------
#FUNCTIONS
#---------
function nginxconfig {
	apt-get install -y ssl-cert
	ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/nginx.key
	ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/nginx.crt
	ln -s /etc/ssl/certs/nginx.crt $WWW_PATH/$GUI_NAME/$HOSTNAME.crt

	#don't forget to escape 'DELIM'. otherwise the $fastcgi part
	#gets escaped.
	#manually escaping now. needs variables....
	/bin/cat > /etc/nginx/sites-available/$GUI_NAME  <<DELIM
server{
        listen 127.0.0.1:80;
        server_name 127.0.0.1;
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        client_max_body_size 10M;
        client_body_buffer_size 128k;


        location / {
          root $WWW_PATH/$GUI_NAME;
          index index.php;
        }

        location ~ \.php$ {
            fastcgi_pass 127.0.0.1:9000;
            #fastcgi_pass /var/run/php5-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param   SCRIPT_FILENAME $WWW_PATH/$GUI_NAME\$fastcgi_script_name;
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
        server_name $GUI_NAME;
        if (\$uri !~* ^.*provision.*$) {
                rewrite ^(.*) https://\$host\$1 permanent;
                break;
        }
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/.error.log;

        client_max_body_size 10M;
        client_body_buffer_size 128k;


        location / {
          root $WWW_PATH/$GUI_NAME;
          index index.php;
        }

        location ~ \.php$ {
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param   SCRIPT_FILENAME $WWW_PATH/$GUI_NAME\$fastcgi_script_name;
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
        server_name $GUI_NAME;
        ssl                     on;
        ssl_certificate         /etc/ssl/certs/nginx.crt;
        ssl_certificate_key     /etc/ssl/private/nginx.key;
        ssl_protocols           SSLv3 TLSv1;
        ssl_ciphers     HIGH:!ADH:!MD5;

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/.error.log;

        client_max_body_size 10M;
        client_body_buffer_size 128k;


        location / {
          root $WWW_PATH/$GUI_NAME;
          index index.php;
        }

        location ~ \.php$ {
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param   SCRIPT_FILENAME $WWW_PATH/$GUI_NAME\$fastcgi_script_name;
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
		/bin/ln -s /etc/nginx/sites-available/$GUI_NAME /etc/nginx/sites-enabled/$GUI_NAME

		/bin/echo "document root for nginx is:"
		/bin/echo "  $WWW_PATH/$GUI_NAME"
		/bin/echo "  php has an upload file size limit of 10 MegaBytes"
		/bin/echo
		/bin/echo "now install FusionPBX. This should go fast."
		/bin/echo

		#nginx install doesn't create /var/www
		/bin/mkdir $WWW_PATH
		/bin/chown -R www-data:www-data $WWW_PATH
		/bin/chmod -R 775 $WWW_PATH

	/etc/init.d/php5-fpm
	/etc/init.d/nginx restart
}


function fusionfail2ban {

/bin/cat > /etc/fail2ban/filter.d/$GUI_NAME.conf  <<'DELIM'
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
DELIM

/bin/grep -i $GUI_NAME /etc/fail2ban/jail.local > /dev/null

if [ $? -eq 0 ]; then
	/bin/echo "FusionPBX Jail already set"
else
	/bin/cat >> /etc/fail2ban/jail.local  <<DELIM
[$GUI_NAME]

enabled  = true
port     = 80,443
protocol = tcp
filter   = $GUI_NAME
logpath  = /var/log/auth.log
action   = iptables-allports[name=$GUI_NAME, protocol=all]
#          sendmail-whois[name=$GUI_NAME, dest=root, sender=fail2ban@example.org] #no smtp server installed
maxretry = 5
findtime = 600
bantime  = 600	
DELIM
fi
}

function www_permissions {
	#consider not stopping here... it's causing some significant delays, or just pause until it starts back up...
	#/etc/init.d/freeswitch stop
	/usr/sbin/adduser www-data audio
	/usr/sbin/adduser www-data dialout
	/bin/echo "setting FreeSWITCH owned by www-dat.www-data"
	/bin/chown -R www-data.www-data /usr/local/freeswitch
	#remove 'other' permissions on freeswitch
	/bin/chmod -R o-rwx /usr/local/freeswitch/
	#set FreeSWITCH directories full permissions for user/group with group sticky
	/bin/echo "Setting group ID sticky for FreeSWITCH"
	/usr/bin/find /usr/local/freeswitch -type d -exec /bin/chmod u=rwx,g=srx,o= {} \;
	#make sure FreeSWITCH directories have group write
	/bin/echo "Setting Group Write for FreeSWITCH files"
	/usr/bin/find /usr/local/freeswitch -type f -exec /bin/chmod g+w {} \;
	#make sure FreeSWITCH files have group write
	/bin/echo "Setting Group Write for FreeSWITCH directories"
	/usr/bin/find /usr/local/freeswitch -type d -exec /bin/chmod g+w {} \;
	/bin/echo "setting FusionPBX owned by www-data.www-data just in case"
	if [ -e /var/www/fusionpbx ]; then
		/bin/chown -R www-data.www-data /var/www/fusionpbx
	fi
	/bin/echo "Changing /etc/init.d/freeswitch to start with user www-data"	
	/bin/sed -i -e s,'USER=freeswitch','USER=www-data', /etc/init.d/freeswitch
	#/etc/init.d/freeswitch start
}

function finish_fpbx_install_permissions {
	/bin/echo
	/bin/echo "The FusionPBX installation changed permissions of /usr/local/freeswitch/storage"
	/bin/echo "  Waiting on you to finish installation (via browser), I'll clean up"
	/bin/echo -ne "  the last bit of permissions when you finish."
	/bin/echo "Waiting on $WWW_PATH/$GUI_NAME/includes/config.php"
	while [ ! -e $WWW_PATH/$GUI_NAME/includes/config.php ]
	do
		/bin/echo -ne '.'
		sleep 1
	done
	/bin/echo
	/bin/echo "$WWW_PATH/$GUI_NAME/includes/config.php Found!"
	/bin/echo "   Waiting 5 more seconds to be sure. "
	SLEEPTIME=0
	while [ "$SLEEPTIME" -lt 5 ]
	do
		/bin/echo -ne '.'
		sleep 1
		let "SLEEPTIME = $SLEEPTIME + 1"
	done

	/bin/echo "   Fixing..."
	/usr/bin/find /usr/local/freeswitch -type f -exec /bin/chmod g+w {} \;
	/usr/bin/find /usr/local/freeswitch -type d -exec /bin/chmod g+w {} \;
	/bin/echo "   FIXED"
}

function build_modules {
	#bandaid
	sed -i -e "s/applications\/mod_voicemail_ivr/#applications\/mod_voicemail_ivr/" $SRCPATH/modules.conf
	#------------
	#  new way v2
	#------------
	#find the default modules - redundant really...
	modules_comp_default=( `/bin/grep -v ^$ /usr/src/freeswitch/modules.conf |/bin/grep -v ^# | /usr/bin/tr '\n' ' '` )
	#add the directory prefixes to the modules in array so the modules we wish to add will compile
	module_count=`echo ${#modules_add[@]}`
	index=0
	while [ "$index" -lt "$module_count" ]
	do
			modules_compile_add[$index]=`/bin/grep ${modules_add[$index]} $SRCPATH/modules.conf | sed -e "s/#//g"`
			let "index = $index + 1"
	done

	modules_compile=( ${modules_comp_default[*]} ${modules_compile_add[*]} )


	#BUILD MODULES.CONF for COMPILER
	echo
	echo
	echo "Now enabling modules for compile in $SRCPATH/modules.conf"
	index=0
	module_count=`echo ${#modules_compile[@]}`
	#get rid of funky spacing in modules.conf
	/bin/sed -i -e "s/ *//g" $SRCPATH/modules.conf
	while [ "$index" -lt "$module_count" ]
	do
			grep ${modules_compile[$index]} $SRCPATH/modules.conf > /dev/null
			if [ $? -eq 0 ]; then
					#module is present in file. see if we need to enable it
					grep '#'${modules_compile[$index]} $SRCPATH/modules.conf > /dev/null
					if [ $? -eq 0 ]; then
							/bin/sed -i -e s,'#'${modules_compile[$index]},${modules_compile[$index]}, $SRCPATH/modules.conf
							/bin/echo "     [ENABLED] ${modules_compile[$index]}"
					else
							/bin/echo "     ${modules_compile[$index]} ALREADY ENABLED!"
					fi

			else
					#module is not present. Add to end of file
					#/bin/echo "did not find ${modules_compile[$index]}"
					/bin/echo ${modules_compile[$index]} >> $SRCPATH/modules.conf
					/bin/echo "     [ADDED] ${modules_compile[$index]}"
			fi

			let "index = $index + 1"
	done
	#--------------
	#end new way v2
	#--------------
}

function enable_modules {
	#------------
	#  new way v2
	#------------
	#ENABLE MODULES for FreeSWITCH
	#
	echo
	echo
	echo "Now enabling modules for FreeSWITCH in $EN_PATH/modules.conf.xml"
	index=0
	module_count=`echo ${#modules_add[@]}`
	#get rid of any funky whitespace
	/bin/sed -i -e s,'<!-- *<','<!--<', -e s,'> *-->','>-->', $EN_PATH/modules.conf.xml
	while [ "$index" -lt "$module_count" ]
	do
		#more strangness to take care of, example:
		#Now enabling modules for FreeSWITCH in /usr/local/freeswitch/conf/autoload_configs/modules.conf.xml
		#[ADDED] ../../libs/freetdm/mod_freetdm
		modules_add[$index]=`/bin/echo ${modules_add[$index]} | /bin/sed -e 's/.*mod_/mod_/'`
		grep ${modules_add[$index]} $EN_PATH/modules.conf.xml > /dev/null
		if [ $? -eq 0 ]; then
			#module is present in file, see if we need to enable it.
			grep  '<!--<load module="'${modules_add[$index]}'"/>-->' $EN_PATH/modules.conf.xml > /dev/null
			if [ $? -eq 0 ]; then
				#/bin/echo "found ${modules_compile[$index]}"
				/bin/sed -i -e s,'<!--<load module="'${modules_add[$index]}'"/>-->','<load module="'${modules_add[$index]}'"/>', \
				  $EN_PATH/modules.conf.xml
				/bin/echo "     [ENABLED] ${modules_add[$index]}"
			else
				/bin/echo "     ${modules_add[$index]} ALREADY ENABLED!"
			fi
        else
			#not in file. we need to add, and will do so below <modules> tag at top of file
			/bin/sed -i -e s,'<modules>','&\n <load module="'${modules_add[$index]}'"/>',  $EN_PATH/modules.conf.xml
			/bin/echo "     [ADDED] ${modules_add[$index]}"
		fi

		let "index = $index + 1"
	done

	#--------------
	#end new way v2
	#--------------
}

function freeswitch_logfiles {
	/bin/echo
	/bin/echo "logrotate not happy with FS: see http://wiki.fusionpbx.com/index.php?title=RotateFSLogs doing differently now..."
	/bin/echo "       SEE: /etc/cron.daily/freeswitch_log_rotation"
	/bin/cat > /etc/cron.daily/freeswitch_log_rotation <<'DELIM'
#!/bin/bash
# logrotate replacement script
# put in /etc/cron.daily
# don't forget to make it executable
# you might consider changing /usr/local/freeswitch/conf/autoload_configs/logfile.conf.xml
#  <param name="rollover" value="0"/>

#number of days of logs to keep
NUMBERDAYS=30
FSPATH="/usr/local/freeswitch"

$FSPATH/bin/fs_cli -x "fsctl send_sighup" |grep '+OK' >/tmp/rotateFSlogs
if [ $? -eq 0 ]; then
       #-cmin 2 could bite us (leave some files uncompressed, eg 11M auto-rotate). Maybe -1440 is better?
       find $FSPATH/log/ -name "freeswitch.log.*" -cmin -2 -exec gzip {} \;
       find $FSPATH/log/ -name "freeswitch.log.*.gz" -mtime +$NUMBERDAYS -exec /bin/rm {} \;
       chown www-data.www-data $FSPATH/log/freeswitch.log
       chmod 660 $FSPATH/log/freeswitch.log
       logger FreeSWITCH Logs rotated
       /bin/rm /tmp/rotateFSlogs
else
       logger FreeSWITCH Log Rotation Script FAILED
       mail -s '$HOST FS Log Rotate Error' root < /tmp/rotateFSlogs
       /bin/rm /tmp/rotateFSlogs
fi
DELIM

	/bin/chmod 755 /etc/cron.daily/freeswitch_log_rotation

	/bin/echo "Now dropping 10MB limit from FreeSWITCH"
	/bin/echo "  This is so the rotation/compression part of the cron script"
	/bin/echo "  will work properly."
	/bin/echo "  SEE: /usr/local/freeswitch/conf/autoload_configs/logfile.conf.xml"

	# <param name="rollover" value="10485760"/>
	/bin/sed /usr/local/freeswitch/conf/autoload_configs/logfile.conf.xml -i -e s,\<param.*name\=\"rollover\".*value\=\"10485760\".*/\>,\<\!\-\-\<param\ name\=\"rollover\"\ value\=\"10485760\"/\>\ INSTALL_SCRIPT\-\-\>,g
}

case $1 in
	fix-https)
		nginxconfig
	;;

	fix-permissions)
		/etc/init.d/freeswitch stop
		www_permissions
		/etc/init.d/freeswitch start
	;;

	install-freeswitch)
		INSFUSION=0
		INSFREESWITCH=1
		UPGFUSION=0
		UPGFREESWITCH=0
	
	;;

	install-fusionpbx)
		INSFUSION=1
		INSFREESWITCH=0
		UPGFUSION=0
		UPGFREESWITCH=0
	;;

	install-both)
		INSFUSION=1
		INSFREESWITCH=1
		UPGFUSION=0
		UPGFREESWITCH=0
	;;

	upgrade-fusionpbx)
		INSFUSION=0
		INSFREESWITCH=0
		UPGFUSION=1
		UPGFREESWITCH=0
	;;

	upgrade-freeswitch)
		INSFUSION=0
		INSFREESWITCH=0
		UPGFUSION=0
		UPGFREESWITCH=1
	;;

	upgrade-both)
		INSFUSION=0
		INSFREESWITCH=0
		UPGFUSION=1
		UPGFREESWITCH=1
	;;

	version)
		/bin/echo "  "$VERSION
		/bin/echo
		/bin/echo "$LICENSE"
		exit 0
	;;

	-v)
		/bin/echo "  "$VERSION
		/bin/echo
		/bin/echo "$LICENSE"
		exit 0
	;;

	--version)
		/bin/echo "  "$VERSION
		/bin/echo
		/bin/echo "$LICENSE"
		exit 0
	;;
	*)
		/bin/echo
		/bin/echo "This script should be called as:"
		/bin/echo "  install_fusionpbx option1 option2"
		/bin/echo
		/bin/echo "    option1:"
		/bin/echo "      install-freeswitch"
		/bin/echo "      install-fusionpbx"
		/bin/echo "      install-both"
		/bin/echo "      upgrade-freeswitch"
		/bin/echo "      upgrade-fusionpbx"
		/bin/echo "      fix-https"
		/bin/echo "      fix-permissions"
		/bin/echo "      version|--version|-v"
		/bin/echo
		/bin/echo "    option2:"
		/bin/echo "      user: option waits in certain places for the user to check for errors"
		/bin/echo "            it is interactive and prompts you about what to install"
		/bin/echo "      auto: tries an automatic install. Get a cup of coffee, this will"
		/bin/echo "            take a while. FOR THE BRAVE!"
		/bin/echo 
		/bin/echo "      EXAMPLE"
		/bin/echo "         install_fusionpbx install-both user"
		/bin/echo 
		exit 0
	;;
esac

case $2 in
	user)
		DEBUG=1
	;;
	auto)
		DEBUG=0
	;;
		*)
		/bin/echo
		/bin/echo "This script should be called as:"
		/bin/echo "  install_fusionpbx option1 option2"
		/bin/echo
		/bin/echo "    option1:"
		/bin/echo "      install-freeswitch"
		/bin/echo "      install-fusionpbx"
		/bin/echo "      install-both"
		/bin/echo "      upgrade-freeswitch"
		/bin/echo "      upgrade-fusionpbx"
		/bin/echo "      fix-https"
		/bin/echo "      fix-permissions"
		/bin/echo "      version|--version|-v"
		/bin/echo
		/bin/echo "    option2:"
		/bin/echo "      user: option waits in certain places for the user to check for errors"
		/bin/echo "            it is interactive and prompts you about what to install"		
		/bin/echo "      auto: tries an automatic install. Get a cup of coffee, this will"
		/bin/echo "            take a while. FOR THE BRAVE!"
		/bin/echo 
		/bin/echo "      EXAMPLE"
		/bin/echo "         install_fusionpbx install-both user"
		/bin/echo 
		exit 0
	;;
esac


#---------------------
#   ENVIRONMENT CHECKS
#---------------------
#check for root
if [ $EUID -ne 0 ]; then
   /bin/echo "This script must be run as root" 1>&2
   exit 1
fi
echo "Good, you are root."

if [ ! -s /usr/bin/lsb_release ]; then
	/bin/echo "Tell your upstream distro to include lsb_release"
	/bin/echo
	apt-get upgrade && apt-get -y install lsb-release
fi

#check for internet connection
/usr/bin/wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google &> /dev/null
if [ ! -s /tmp/index.google ];then
	echo "No Internet connection. Exiting."
	/bin/rm /tmp/index.google
	exit 1
else
	echo "Internet connection is working, continuing!"
	/bin/rm /tmp/index.google
fi


#check for 10.04 LTS Lucid

#/bin/grep -i lucid /etc/lsb-release > /dev/null
lsb_release -c |grep -i lucid > /dev/null
if [ $? -eq 0 ]; then
	DISTRO=lucid
	/bin/echo "Good, you're running Ubuntu 10.04 LTS codename Lucid"
	/bin/echo
else
	lsb_release -c |grep -i squeeze > /dev/null
	if [ $? -eq 0 ]; then
		DISTRO=squeeze
		/bin/echo "OK you're running Debian Squeeze.  This script is known to work"
		/bin/echo "   with apache/nginx and mysql|sqlite|postgres8 options"
		/bin/echo "   Please consider providing feedback on repositories for nginx"
		/bin/echo "   and php-fpm."
		/bin/echo 
		CONTINUE=YES
	fi
	lsb_release -c |grep -i precise > /dev/null
	if [ $? -eq 0 ]; then
		DISTRO=precise
		/bin/echo "OK you're running Ubuntu 12.04 LTS [precise].  This script is"
		/bin/echo "   a work in progress.  It is not recommended that you try it"
		/bin/echo "   at this time."
		/bin/echo 
		CONTINUE=YES
	else
		/bin/echo "This script was written for Ubuntu 10.04 LTS codename Lucid"
		/bin/echo
		/bin/echo "Your OS appears to be:"
		lsb_release -a
		read -p "Do you want to continue [y|n]? " CONTINUE

		case "$CONTINUE" in
		[yY]*)
			/bin/echo "Ok, this doesn't always work..,"
			/bin/echo "  but we'll give it a go."
		;;

		*)
			/bin/echo "Quitting."
			exit 1
		;;
		esac
	fi
fi

#Check for new version
WHEREAMI=$(echo "`pwd`/`basename $0`")
wget $URLSCRIPT -O /tmp/install_fusionpbx.latest
CURMD5=$(md5sum "$WHEREAMI" | sed -e "s/\ .*//")
echo "The md5sum of the current script is: $CURMD5"
NEWMD5=$(md5sum /tmp/install_fusionpbx.latest | sed -e "s/\ .*//")
echo "The md5sum of the latest script is: $NEWMD5"

if [[ "$CURMD5" == "$NEWMD5" ]]; then
	echo "files are the same, continuing"
else
	echo "There is a new version of this script."
	echo "  It is PROBABLY a good idea use the new version"
	echo "  the new file is saved in /tmp/install_fusionpbx.latest"
	echo "  to see the difference, run:"
	echo "  diff -y /tmp/install_fusionpbx.latest $WHEREAMI"
	read -p "Continue [y/N]? " YESNO
	case $YESNO in
		[Yy]*)
			echo "OK, Continuing"
			echo "  Deleting newest script in /tmp"
			rm /tmp/install_fusionpbx.latest
		;;

		*)
			echo "OK, Stopping."
			exit 0
		;;
	esac
fi


#----------------------
#END ENVIRONMENT CHECKS
#----------------------

#---------------------------------------
#       INSTALL    FREESWITCH
#---------------------------------------
if [ $INSFREESWITCH -eq 1 ]; then

	/bin/echo "Upgrading the system, and adding the necessary dependencies for a FreeSWITCH compile"
	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		read -p "Press Enter to continue..."
	fi

	/usr/bin/apt-get update
	/usr/bin/apt-get -y upgrade

	if [ $DISTRO = "precise" ]; then
		/usr/bin/apt-get -y install ssh vim git-core subversion build-essential \
		autoconf automake libtool libncurses5 libncurses5-dev libjpeg-dev ssh \
		screen htop pkg-config bzip2 curl libtiff4-dev ntp \
		time bison libssl-dev \
		unixodbc libmyodbc unixodbc-dev libtiff-tools
	else
		/usr/bin/apt-get -y install ssh vim git-core subversion build-essential \
			autoconf automake libtool libncurses5 libncurses5-dev libjpeg62-dev ssh \
			screen htop pkg-config bzip2 curl libtiff4-dev ntp \
			time bison libssl-dev \
			unixodbc libmyodbc unixodbc-dev libtiff-tools
	fi

	#added libgnutls-dev libgnutls26 for dingaling...
	#gnutls no longer required for dingaling (git around oct 17 per mailing list..)
	# removed libgnutls-dev libgnutls26
if [ $DO_DAHDI == "y" ]; then
		#add stuff for free_tdm/dahdi
		apt-get -y install linux-headers-`uname -r`
		#add the headers so dahdi can build the modules...
		apt-get -y install dahdi
	fi

	LDRUN=0
	/bin/echo -ne "Waiting on ldconfig to finish so bootstrap will work"
	while [ $LDRUN -eq 0 ]
	do
			echo -ne "."
			sleep 1
			/usr/bin/pgrep -f ldconfig > /dev/null
			LDRUN=$?
	done

	/bin/echo
	/bin/echo
	/bin/echo "ldconfig is finished"
	/bin/echo

	if [ ! -e /tmp/install_fusion_status ]; then
		touch /tmp/install_fusion_status
	fi

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		read -p "Press Enter to continue (check for errors)"
	fi

	#------------------------
	# GIT FREESWITCH
	#------------------------
	/bin/grep 'git_done' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "Git Already Done. Skipping"	
	else
		cd /usr/src
		if [ "$FSSTABLE" == true ]; then
			echo "installing stable $FSStableVer of FreeSWITCH"
			/usr/bin/time /usr/bin/git clone $FSGIT
			cd /usr/src/freeswitch
			/usr/bin/git checkout $FSStableVer
			if [ $? -ne 0 ]; then
				#git had an error
				/bin/echo "GIT ERROR"
				exit 1
			fi
		else
			if [ $FSCHECKOUTVER == true ]; then
				echo "OK we'll check out FreeSWITCH version $FSREV"
				cd /usr/src/freeswitch
				/usr/bin/git checkout $FSREV
				if [ $? -ne 0 ]; then
					#git checkout had an error
					/bin/echo "GIT CHECKOUT ERROR"
					exit 1
				fi
			else
				echo "going dev branch.  Hope this works for you."
				/usr/bin/time /usr/bin/git clone $FSGIT
				if [ $? -ne 0 ]; then
					#git had an error
					/bin/echo "GIT ERROR"
					exit 1
				fi
			fi
			/bin/echo "git_done" >> /tmp/install_fusion_status
		fi
	fi

	if [ -e /usr/src/FreeSWITCH ]; then
		/bin/ln -s /usr/src/FreeSWITCH /usr/src/freeswitch
	elif [ -e /usr/src/freeswitch.git ]; then
		/bin/ln -s /usr/src/freeswitch.git /usr/src/freeswitch
	fi

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		read -p "Press Enter to continue (check for errors)"
	fi

	#------------------------
	# BOOTSTRAP FREESWITCH
	#------------------------
	/bin/grep 'bootstrap_done' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "Bootstrap already done. skipping"
	else
		#might see about -j option to bootstrap.sh
		/etc/init.d/ssh start
		cd /usr/src/freeswitch
		/bin/echo
		/bin/echo "FreeSWITCH Downloaded"
		/bin/echo 
		/bin/echo "Bootstrapping."
		/bin/echo
		#next line failed (couldn't find file) not sure why.
		#it did run fine a second time.  Go figure (really).
		#ldconfig culprit?
		if [ $CORES -gt 1 ]; then 
			/bin/echo "  multicore processor detected. Starting Bootstrap with -j"
			if [ $DEBUG -eq 1 ]; then
				/bin/echo
				read -p "Press Enter to continue (check for errors)"
			fi
			/usr/bin/time /usr/src/freeswitch/bootstrap.sh -j
		else 
			/bin/echo "  singlecore processor detected. Starting Bootstrap sans -j"
			if [ $DEBUG -eq 1 ]; then
				/bin/echo
				read -p "Press Enter to continue (check for errors)"
			fi
			/usr/bin/time /usr/src/freeswitch/bootstrap.sh
		fi

		if [ $? -ne 0 ]; then
			#bootstrap had an error
			/bin/echo "BOOTSTRAP ERROR"
			exit 1
		else
			/bin/echo "bootstrap_done" >> /tmp/install_fusion_status
		fi
	fi

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		read -p "Press Enter to continue (check for errors)"
	fi

	#------------------------
	# build modules.conf 
	#------------------------
	/bin/grep 'build_modules' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "Modules.conf Already edited"	
	else
		#file exists and has been edited
		build_modules
		#check exit status
		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "ERROR: Failed to enable build modules in modules.conf."
			exit 1
		else
			/bin/echo "build_modules" >> /tmp/install_fusion_status
		fi
	fi

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		read -p "Press Enter to continue (check for errors)"
	fi

	#------------------------
	# CONFIGURE FREESWITCH 
	#------------------------
	/bin/grep 'config_done' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "FreeSWITCH already Configured! Skipping."
	else
		/bin/echo
		/bin/echo -ne "Configuring FreeSWITCH. This will take a while [~15 minutes]"
		/bin/sleep 1
		/bin/echo -ne " ."
		/bin/sleep 1
		/bin/echo -ne " ."
		/bin/sleep 1
		/bin/echo -ne " ."
		/usr/bin/time /usr/src/freeswitch/configure

		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "ERROR: FreeSWITCH Configure ERROR."
			exit 1
		else
			/bin/echo "config_done" >> /tmp/install_fusion_status
		fi
	fi

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		read -p "Press Enter to continue (check for errors)"
	fi

	if [ -a /etc/init.d/freeswitch ]; then
		/bin/echo " In case of an install where FS exists (iso), stop FS"
		/etc/init.d/freeswitch stop
	fi


	#------------------------
	# COMPILE FREESWITCH 
	#------------------------
	/bin/grep 'compile_done' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "FreeSWITCH already Compiled! Skipping."
	else
		#might see about -j cores option to make...

		/bin/echo
		/bin/echo -ne "Compiling FreeSWITCH. This might take a LONG while [~30 minutes]"
		/bin/sleep 1
		/bin/echo -ne "."
		/bin/sleep 1
		/bin/echo -ne "."
		/bin/sleep 1
		/bin/echo -ne "."

		#making sure pwd is correct
		cd /usr/src/freeswitch
		if [ $CORES -gt 1 ]; then 
			/bin/echo "  multicore processor detected. Compiling with -j $CORES"
			#per anthm compile the freeswitch core first, then the modules.
			/usr/bin/time /usr/bin/make -j $CORES core
			/usr/bin/time /usr/bin/make -j $CORES
		else 
			/bin/echo "  singlecore processor detected. Starting compile sans -j"
			/usr/bin/time /usr/bin/make 
		fi

		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "ERROR: FreeSWITCH Build Failure."
			exit 1
		else
			/bin/echo "compile_done" >> /tmp/install_fusion_status
		fi
	fi

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		read -p "Press Enter to continue (check for errors)"
	fi

	#------------------------
	# INSTALL FREESWITCH 
	#------------------------
	/bin/grep 'install_done' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "FreeSWITCH already Installed! Skipping."
	else
		#dingaling/ubuntu has an issue. let's edit the file...
		#"--mode=relink gcc" --> "--mode=relink gcc -lgnutls" 

		#tls no longer required for dingaling, so this weird issue doesn't happen. now uses openssl.
#		/bin/grep 'lgnutls' /usr/src/freeswitch/src/mod/endpoints/mod_dingaling/mod_dingaling.la > /dev/null
#		if [ $? -eq 0 ]; then
#			/bin/echo "dingaling fix already applied."
#		else
#			/bin/sed -i -e s,'--mode=relink gcc','--mode=relink gcc -lgnutls', /usr/src/freeswitch/src/mod/endpoints/mod_dingaling/mod_dingaling.la
#		fi
		cd /usr/src/freeswitch
		if [ $CORES -gt 1 ]; then 
			/bin/echo "  multicore processor detected. Installing with -j $CORES"
			/usr/bin/time /usr/bin/make -j $CORES install
		else 
			/bin/echo "  singlecore processor detected. Starting install sans -j"
			/usr/bin/time /usr/bin/make install
		fi
		#/usr/bin/time /usr/bin/make install

		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "ERROR: FreeSWITCH INSTALL Failure."
			exit 1
		else
			/bin/echo "install_done" >> /tmp/install_fusion_status
		fi
	fi

	#------------------------
	# FREESWITCH  HD SOUNDS
	#------------------------
	/bin/grep 'sounds_done' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "FreeSWITCH HD SOUNDS DONE! Skipping."
	else
		/bin/echo
		/bin/echo -ne "Installing FreeSWITCH HD sounds (16/8khz). This will take a while [~10 minutes]"
		/bin/sleep 1
		/bin/echo -ne "."
		/bin/sleep 1
		/bin/echo -ne "."
		/bin/sleep 1
		/bin/echo "."
		cd /usr/src/freeswitch
		if [ $CORES -gt 1 ]; then 
			/bin/echo "  multicore processor detected. Installing with -j $CORES"
			/usr/bin/time /usr/bin/make -j $CORES hd-sounds-install
		else 
			/bin/echo "  singlecore processor detected. Starting install sans -j"
			/usr/bin/time /usr/bin/make hd-sounds-install
		fi
		#/usr/bin/time /usr/bin/make hd-sounds-install

		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "ERROR: FreeSWITCH make cdsounds-install ERROR."
			exit 1
		else
			/bin/echo "sounds_done" >> /tmp/install_fusion_status
		fi
	fi

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		read -p "Press Enter to continue (check for errors)"
	fi


	#------------------------
	# FREESWITCH  MOH
	#------------------------
	/bin/grep 'moh_done' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "FreeSWITCH MOH DONE! Skipping."
	else
		/bin/echo
		/bin/echo -ne "Installing FreeSWITCH HD Music On Hold sounds (16/8kHz). This will take a while [~10 minutes]"
		/bin/sleep 1
		/bin/echo -ne "."
		/bin/sleep 1
		/bin/echo -ne "."
		/bin/sleep 1
		/bin/echo "."

		cd /usr/src/freeswitch
		if [ $CORES -gt 1 ]; then 
			/bin/echo "  multicore processor detected. Installing with -j $CORES"
			/usr/bin/time /usr/bin/make -j $CORES hd-moh-install
		else 
			/bin/echo "  singlecore processor detected. Starting install sans -j"
			/usr/bin/time /usr/bin/make hd-moh-install
		fi
		#/usr/bin/make hd-moh-install

		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "ERROR: FreeSWITCH make cd-moh-install ERROR."
			exit 1
		else
			/bin/echo "moh_done" >> /tmp/install_fusion_status
		fi
	fi

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		read -p "Press Enter to continue (check for errors)"
	fi

	#------------------------
	# FREESWITCH INIT
	#------------------------
	#no need for tmp file. already handled...
	/bin/echo
	/bin/echo "Configuring /etc/init.d/freeswitch"

	/bin/grep local /etc/init.d/freeswitch > /dev/null
	if [ $? -eq 0 ]; then
		#file exists and has been edited
		/bin/echo "/etc/init.d/freeswitch already edited, skipping"
	elif [ -e /usr/src/freeswitch/debian/freeswitch.init ]; then
		/bin/sed /usr/src/freeswitch/debian/freeswitch.init -e s,opt,usr/local, >/etc/init.d/freeswitch
	else
		/bin/sed /usr/src/freeswitch/debian/freeswitch-sysvinit.freeswitch.init  -e s,opt,usr/local, >/etc/init.d/freeswitch
		#DAEMON
		/bin/sed -i /etc/init.d/freeswitch -e s,^DAEMON=.*,DAEMON=/usr/local/freeswitch/bin/freeswitch,

		#DAEMON_ARGS
		/bin/sed -i /etc/init.d/freeswitch -e s,'^DAEMON_ARGS=.*','DAEMON_ARGS="-u www-data -g www-data -rp -nc -nonat"',

		#PIDFILE
		/bin/sed -i /etc/init.d/freeswitch -e s,^PIDFILE=.*,PIDFILE=/usr/local/freeswitch/run/\$NAME.pid,

		#WORKDIR
		/bin/sed -i /etc/init.d/freeswitch -e s,^WORKDIR=.*,WORKDIR=/usr/local/freeswitch/lib/,
	fi

	if [ $? -ne 0 ]; then
		#previous had an error
		/bin/echo "ERROR: Couldn't edit FreeSWITCH init script."
		exit 1
	fi

	/bin/chmod 755 /etc/init.d/freeswitch
	/bin/echo "enabling FreeSWITCH to start at boot"

	/bin/grep true /etc/default/freeswitch > /dev/null
	if [ $? -eq 0 ]; then
		#file exists and has been edited
		/bin/echo "/etc/default/freeswitch already edited, skipping"
	else
		if [ -e /usr/src/freeswitch/debian/freeswitch-sysvinit.freeswitch.default ]; then
			/bin/sed /usr/src/freeswitch/debian/freeswitch-sysvinit.freeswitch.default -e s,false,true, > /etc/default/freeswitch
			if [ $? -ne 0 ]; then
					#previous had an error
					/bin/echo "ERROR: Couldn't edit freeswitch RC script."
					exit 1
			fi
		else
			/bin/sed /usr/src/freeswitch/debian/freeswitch.default -e s,false,true, > /etc/default/freeswitch
			if [ $? -ne 0 ]; then
				#previous had an error
				/bin/echo "ERROR: Couldn't edit freeswitch RC script."
				exit 1
			fi
		fi
		if [ $DEBUG -eq 1 ]; then
			/bin/echo "Checking for a public IP Address..."

			PUBLICIP=no

			#turn off the auto-nat when we start freeswitch.
			#nasty syntax. searches for 10.a.b.c or 192.168.x.y addresses in ifconfig.
			/sbin/ifconfig | \
			/bin/grep 'inet addr:' | \
			/usr/bin/cut -d: -f2 | \
			/usr/bin/awk '{ print $1}' | \
			while read IPADDR; do
				echo "$IPADDR" | \
				/bin/grep -e '^10\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$' \
					-e '^192\.168\.[0-9]\{1,3\}\.[0-9]\{1,3\}$' \
					-e '^127.0.0.1$'
					#-e '^172\.[16-31]\.[0-9]\{1,3\}\.[0-9]\{1,3\}' \

				if [ $? -ne 0 ]; then
					PUBLICIP=yes
				fi
			done

			case "$PUBLICIP" in 
				[Yy]*)
					if [ $DEBUG -eq 1 ]; then  
						/bin/echo "You appear to have a public IP address."
						/bin/echo " I can make sure FreeSWITCH starts with"
						/bin/echo " the -nonat option (starts quicker)."
						/bin/echo 
						read -p "Would you like for me to do this (y/n)? " SETNONAT
					fi
				
				;;

				*)
					/bin/echo "Dynamic IP. leaving FreeSWITCH for aggressive nat"
					SETNONAT=no
				;;
			esac
		fi

		case "$SETNONAT" in
			[Yy]*)
				/bin/sed /etc/default/freeswitch -i -e s,'FREESWITCH_PARAMS="-nc"','FREESWITCH_PARAMS="-nc -nonat"',
				/bin/echo "init script set to start 'freeswitch -nc -nonat'"
			;;

			*)
						/bin/echo "OK, not using -nonat option."
			;;
		esac
		/bin/echo
		/usr/sbin/update-rc.d -f freeswitch defaults
	fi

	/bin/echo

	#don't do this.  If freeswitch is a machine name, it really screws this test.  It
	#won't hurt to adduser a second time anyhow.
	#/bin/grep freeswitch /etc/passwd > /dev/null
	#if [ $? -eq 0 ]; then
		#user already exists
	#	/bin/echo "FreeSWITCH user already exists, skipping..."
	#else
	/bin/echo "adding freeswitch user"
	/usr/sbin/adduser --disabled-password  --quiet --system \
		--home /usr/local/freeswitch \
		--gecos "FreeSWITCH Voice Platform" --ingroup daemon \
		freeswitch

	if [ $? -ne 0 ]; then
		#previous had an error
		/bin/echo "ERROR: Failed adding freeswitch user."
		exit 1
	fi
	#fi

	/usr/sbin/adduser freeswitch audio

	if [ $DO_DAHDI == "y" ]; then
		#dialout for dahdi
		/usr/sbin/adduser freeswitch dialout
	fi

	/bin/chown -R freeswitch:daemon /usr/local/freeswitch/

	/bin/echo "removing 'other' permissions on freeswitch"
	/bin/chmod -R o-rwx /usr/local/freeswitch/
	/bin/echo
	cd /usr/local/
	/bin/chown -R freeswitch:daemon /usr/local/freeswitch
	/bin/echo "FreeSWITCH directories now owned by freeswitch.daemon"
	/usr/bin/find freeswitch -type d -exec /bin/chmod u=rwx,g=srx,o= {} \;
	/bin/echo "FreeSWITCH directories now sticky group. This will cause any files created"
	/bin/echo "  to default to the daemon group so FreeSWITCH can read them"
	/bin/echo
	#/bin/echo "removing /opt blindly (hope nothing is there) and linking it"
	#/bin/echo "  to /usr/local so FusionPBX won't complain"
	#Opt might have been created due to a type in adduser freeswitch (home was /opt) check...
	#this looks to be the case.
	#the latest FusionBPX is correctly detecting /usr/local/freeswitch
	#   probably always did.
	#let's try removing opt altogether...
	#/bin/echo
	/bin/ln -s /usr/local/freeswitch/bin/fs_cli /usr/local/bin/

	#if [ $DEBUG -eq 1 ]; then  
	#	/bin/echo "FreeSWITCH was installed to /usr/local."
	#	/bin/echo " normally we don't want to see /opt"
	#	/bin/echo " since FusionPBX. tries to find it"
	#	/bin/echo " and you end up with having to symlink"
	#	/bin/echo " /usr/local/freeswitch to /opt/freeswitch"
	#	/bin/echo 
	#	/bin/echo " It would be easier to blow /opt away; but"
	#	/bin/echo " this may not be a fresh Ubuntu install."
	#	/bin/echo
	#	read -p "Can I 'rm -Rf /opt (Y/n)? " RMOPT
	#fi

	#case "$RMOPT" in
	#[Yy]*)
	#	/bin/rm -Rf /opt
	#;;

	#*)
		#/bin/echo "OK, linking /usr/local/freeswitch to /opt/freeswitch"
		#/bin/ln -s /usr/local/freeswitch /opt/freeswitch
	#;;

	#esac

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		/bin/echo "Press Enter to continue (check for errors)"
		read
	fi

	#------------------------
	# enable modules.conf.xml
	#------------------------
	/bin/grep 'enable_modules' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "Modules.conf.xml Already enabled"
	else
		#file exists and has been edited
		enable_modules
		#check exit status
		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "ERROR: Failed to enable modules in modules.conf.xml."
			exit 1
		else
			/bin/echo "enable_modules" >> /tmp/install_fusion_status
		fi
	fi

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		read -p "Press Enter to continue (check for errors)"
	fi

	#-----------------
	#Setup logrotate
	#-----------------
#	if [ -a /etc/logrotate.d/freeswitch ]; then
	if [ -a /etc/cron.daily/freeswitch_log_rotation ]; then
		/bin/echo "Logrotate for FreeSWITCH Already Done!"

		#call log script creation function
		freeswitch_logfiles
	fi

	#-----------------
	#harden FreeSWITCH
	#-----------------
	/bin/echo -ne "HARDENING"
	sleep 1
	/bin/echo -ne " ."
	sleep 1
	/bin/echo -ne " ."
	sleep 1
	/bin/echo -ne " ."

	/usr/bin/apt-get -y install fail2ban
	/bin/echo
	/bin/echo "Checking log-auth-failures"
	/bin/grep log-auth-failures /usr/local/freeswitch/conf/sip_profiles/internal.xml > /dev/null
	if [ $? -eq 0 ]; then
		#see if it's uncommented
		/bin/grep log-auth-failures /usr/local/freeswitch/conf/sip_profiles/internal.xml | /bin/grep '<!--' > /dev/null
		if [ $? -eq 1 ]; then
			#Check for true
			/bin/grep log-auth-failures /usr/local/freeswitch/conf/sip_profiles/internal.xml |/bin/grep true > /dev/null
			if [ $? -eq 0 ]; then
				/bin/echo "     [ENABLED] log-auth-failures - Already Done!"
			else
				#it's false and uncommented, change it to true
				/bin/sed -i -e s,'<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>', \
					/usr/local/freeswitch/conf/sip_profiles/internal.xml
				/bin/echo  "     [ENABLED] log-auth-failures - Was False!"
			fi
		else 
			# It's commented
			# check for true
			/bin/grep log-auth-failures /usr/local/freeswitch/conf/sip_profiles/internal.xml |/bin/grep true > /dev/null
			if [ $? -eq 0 ]; then
				#it's commented and true
				/bin/sed -i -e s,'<!-- *<param name="log-auth-failures" value="true"/>','<param name="log-auth-failures" value="true"/>', \
					-e s,'<param name="log-auth-failures" value="true"/> *-->','<param name="log-auth-failures" value="true"/>', \
					-e s,'<!--<param name="log-auth-failures" value="true"/>','<param name="log-auth-failures" value="true"/>', \
					-e s,'<param name="log-auth-failures" value="true"/>-->','<param name="log-auth-failures" value="true"/>', \
					/usr/local/freeswitch/conf/sip_profiles/internal.xml
				/bin/echo  "     [ENABLED] log-auth-failures - Was Commented!"
			else
				#it's commented and false.
				/bin/sed -i -e s,'<!-- *<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>', \
					-e s,'<param name="log-auth-failures" value="false"/> *-->','<param name="log-auth-failures" value="true"/>', \
					-e s,'<!--<param name="log-auth-failures" value="false"/>','<param name="log-auth-failures" value="true"/>', \
					-e s,'<param name="log-auth-failures" value="false"/>-->','<param name="log-auth-failures" value="true"/>', \
					/usr/local/freeswitch/conf/sip_profiles/internal.xml
				/bin/echo  "     [ENABLED] log-auth-failures - Was Commented and False!"
			fi
		fi
	else
		#It's not present...
		/bin/sed -i -e s,'<settings>','&\n <param name="log-auth-failures" value="true"/>', \
			/usr/local/freeswitch/conf/sip_profiles/internal.xml
		/bin/echo  "     [ENABLED] log-auth-failures - Wasn't there!" 
	fi

	if [ -a /etc/fail2ban/filter.d/freeswitch.conf ]; then
		/bin/echo "fail2ban filter for freeswitch already done!"

	else
		/bin/cat > /etc/fail2ban/filter.d/freeswitch.conf  <<"DELIM"
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
failregex = \[WARNING\] sofia_reg.c:\d+ SIP auth failure \(REGISTER\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>
            \[WARNING\] sofia_reg.c:\d+ SIP auth failure \(INVITE\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
DELIM

/bin/cat > /etc/fail2ban/filter.d/freeswitch-dos.conf  <<"DELIM"
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
failregex = \[WARNING\] sofia_reg.c:\d+ SIP auth challenge \(REGISTER\) on sofia profile \'\w+\' for \[.*\] from ip <HOST>

# Option:  ignoreregex
# Notes.:  regex to ignore. If this regex matches, the line is ignored.
# Values:  TEXT
#
ignoreregex =
DELIM

	fi

	#see if we've done this before (as in an ISO was made
	#with this script but the source wasn't included
	#so we have to reinstall...
	/bin/grep freeswitch /etc/fail2ban/jail.local > /dev/null
	if [ $? -ne 0 ]; then
		#add the following stanzas to the end of our file (don't overwrite)
		/bin/cat >> /etc/fail2ban/jail.local  <<'DELIM'
[freeswitch-tcp]
enabled  = true
port     = 5060,5061,5080,5081
protocol = tcp
filter   = freeswitch
logpath  = /usr/local/freeswitch/log/freeswitch.log
action   = iptables-allports[name=freeswitch-tcp, protocol=all]
maxretry = 5
findtime = 600
bantime  = 600
#          sendmail-whois[name=FreeSwitch, dest=root, sender=fail2ban@example.org] #no smtp server installed

[freeswitch-udp]
enabled  = true
port     = 5060,5061,5080,5081
protocol = udp
filter   = freeswitch
logpath  = /usr/local/freeswitch/log/freeswitch.log
action   = iptables-allports[name=freeswitch-udp, protocol=all]
maxretry = 5
findtime = 600
bantime  = 600
#          sendmail-whois[name=FreeSwitch, dest=root, sender=fail2ban@example.org] #no smtp server installed

[freeswitch-dos]
enabled = true
port = 5060,5061,5080,5081
protocol = udp
filter = freeswitch-dos
logpath = /usr/local/freeswitch/log/freeswitch.log
action = iptables-allports[name=freeswitch-dos, protocol=all]
maxretry = 50
findtime = 30
bantime  = 6000
DELIM

	else
		/bin/echo"fail2ban jail.local for freeswitch already done!"
	fi

	#problem with the way ubuntu logs ssh failures [fail2ban]
	#  Failed password for root from 1.2.3.4 port 22 ssh2
	#  last message repeated 5 times
	#  SOLUTION: Turn off RepeatedMsgReduction in rsyslog.
	/bin/echo "Turning off RepeatedMsgReduction in /etc/rsyslog.conf"
	#not sure what the deal is with the single quotes here. Fixed in v4.4.0
	#/bin/sed -i ‘s/RepeatedMsgReduction\ on/RepeatedMsgReduction\ off/’ /etc/rsyslog.conf
	/bin/sed -i 's/RepeatedMsgReduction\ on/RepeatedMsgReduction\ off/' /etc/rsyslog.conf
	/etc/init.d/rsyslog restart

	#bug in fail2ban.  If you see this error
	#2011-02-27 14:11:42,326 fail2ban.actions.action: ERROR  iptables -N fail2ban-freeswitch-tcp
	#http://www.fail2ban.org/wiki/index.php/Fail2ban_talk:Community_Portal#fail2ban.action.action_ERROR_on_startup.2Frestart

	/bin/grep -A 1 'time.sleep(0\.1)' /usr/bin/fail2ban-client |/bin/grep beautifier > /dev/null
	if [ $? -ne 0 ]; then
		/bin/sed -i -e s,beautifier\.setInputCmd\(c\),'time.sleep\(0\.1\)\n\t\t\tbeautifier.setInputCmd\(c\)', /usr/bin/fail2ban-client
		#this does slow the restart down quite a bit.
	else
		/bin/echo '   time.sleep(0.1) already added to /usr/bin/fail2ban-client'
	fi
	#still may have a problem with logrotate causing missing new FS log files.
	#should see log lines such as:
	#2011-02-13 06:37:59,889 fail2ban.filter : INFO   Log rotation detected for /usr/local/freeswitch/log/freeswitch.log
	/etc/init.d/freeswitch start
	/etc/init.d/fail2ban restart

	/bin/echo "     fail2ban for ssh enabled by default"
	/bin/echo "     Default is 3 failures before your IP gets blocked for 600 seconds"
	/bin/echo "      SEE http://wiki.freeswitch.org/wiki/Fail2ban"

	/bin/echo
	/bin/echo
	/bin/echo "FreeSWITCH Installation Completed. Have Fun!"
	/bin/echo

fi

#---------------------------------------
#     DONE INSTALLING FREESWITCH
#---------------------------------------

  
#---------------------------------------
#        INSTALL FUSIONPBX
#---------------------------------------

if [ $INSFUSION -eq 1 ]; then

	/bin/echo "FYI, we will need to change ownership of all FreeSWITCH"
	/bin/echo "  Directories to www-data.www-data"
	/bin/echo "  We will also need to change the init script to"
	/bin/echo "  start FreeSWITCH as the www-data user."
	/bin/echo
	/bin/echo "This is a workaround to FreeSWITCH jira FS-3016"
	/bin/echo "  The better way would be to have FreeSWITCH and FusionPBX"
	/bin/echo "  share group permissions; unfortunately, FreeSWITCH writes"
	/bin/echo "  log files, voicemail, etc with group permissions off."
	/bin/echo
	/bin/echo "This behavior is hard coded into FreeSWITCH."
	/bin/echo "  For now, you need to be aware that if an"
	/bin/echo "  exploit is found for apache2 or nginx"
	/bin/echo "  The attacker would have access to the entire"
	/bin/echo "  FreeSWITCH directory. This isn't quite as bad as it seems though."
	/bin/echo "  since simply having access to configuration can do damage"
	/bin/echo "Watch your logfiles."
	#read -p "   press enter to continue."
	/bin/echo
	/bin/echo "Stopping FreeSWITCH..."
	/etc/init.d/freeswitch stop
	www_permissions

	#Lets ask... nginx or apache -- for user option only
	if [ $DEBUG -eq 1 ]; then
		/bin/echo "New Option..."
		read -p "Would you prefer Apache or Ngnix [nginx and php-fpm from ppa repos] (a/N)? " APACHENGINX
	fi

	#remastersys iso ditches the apt data. have to update
	/usr/bin/apt-get update
	#get reqs for both
	/usr/bin/apt-get -y install python-software-properties subversion ghostscript
	  #provides apt-add-repository
	  #installs python-software-properties unattended-upgrades
	  #/usr/bin/apt-get -y install ppa-purge #in backports. don't want that repo
	if [ ! -e /usr/sbin/ppa-purge ]; then
		/usr/bin/wget http://us.archive.ubuntu.com/ubuntu/pool/universe/p/ppa-purge/ppa-purge_0+bzr46.1~lucid1_all.deb -O /var/cache/apt/archives/ppa-purge_0+bzr46.1~lucid1_all.deb
		/usr/bin/dpkg -i /var/cache/apt/archives/ppa-purge_0+bzr46.1~lucid1_all.deb
	fi

	/usr/bin/apt-get -y install sqlite php5-cli php5-sqlite php5-odbc 
	if [ $DISTRO = "precise" ]; then
		/usr/bin/apt-get -y install php-db
	fi

	#-----------------
	# Apache
	#-----------------
	case "$APACHENGINX" in
	[Aa]*)
	#if [ $APACHENGINX == "a" ]; then
		if [ -e /usr/sbin/nginx ]; then
			#nginx is installed.
			/bin/echo
			/bin/echo "Nginx is installed, and you selected apache2."
			if [ $DEBUG -eq 1 ]; then
				/bin/echo
				/bin/echo "  We need to remove nginx/php5-fpm. The packages"
				/bin/echo "  are not purged, so configuration files will stay."
				/bin/echo
				read -p "  Do you want to remove nginx/php5-fpm and install apache2 (y/n)? " YESNO
			else 
				YESNO=y
			fi
				case "$YESNO" in 
					[Yy]*)
						/bin/grep brianmercer /etc/apt/sources.list > /dev/null
						if [ $? -eq 0 ]; then
							/bin/echo "php-fpm ppa already add the old way. Fixing"
							/bin/sed -i -e s,'deb http://ppa.launchpad.net/brianmercer/php/ubuntu lucid main',, /etc/apt/sources.list
						fi
						/bin/grep nginx /etc/apt/sources.list > /dev/null
						if [ $? -ne 0 ]; then
							/bin/echo "nginx ppa already add the old way. Fixing"
							/bin/sed -i -e s,'deb http://ppa.launchpad.net/nginx/stable/ubuntu lucid main',, /etc/apt/sources.list
						fi
						#remove ppa's
						/usr/sbin/ppa-purge ppa:brianmercer/php
						/usr/sbin/ppa-purge ppa:nginx/stable
						#remove packages
						/usr/bin/apt-get -y remove nginx nginx-full libevent-1.4-2 libt1-5 \
						   php-apc php-pear php5-fpm php5-gd php5-memcache 
						  #ttf-dejavu-core fontconfig-config libfontconfig1 libxpm4 #removes x/gnome
						  #libxslt1.1 libxslt1.1 #removes midori
						  #libgd2-xpm #removed by ppa-purge
						  #libgd2-noxpm #removed by ppa-purge
						/usr/bin/apt-get clean
						/usr/bin/apt-get update
						#re-install removed packages
						/usr/bin/apt-get -y install libgd2-noxpm
						/bin/echo "  NGINX/PHP5-FPM REMOVED!"
					;;
					*)
						/bin/echo "OK. We'll stop. Exiting!"
						exit 1
					;;
				esac
		fi

		/usr/bin/apt-get -y install apache2 libapache2-mod-php5 
		#installs:
		#apache2 apache2-mpm-prefork apache2-utils apache2.2-bin apache2.2-common libapache2-mod-php5 libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap
#		/bin/grep fusionpbx /etc/apache2/sites-enabled/000-default > /dev/null
#		if [ $? -ne 0 ]; then
		if [ ! -e /etc/apache2/sites-enabled/$GUI_NAME ]; then
			#disable the default 000-default site
			/usr/sbin/a2dissite default
			#let's use a heredoc now, and do this the right way. #no 'quotes' with variables
			/bin/cat >> /etc/apache2/sites-available/$GUI_NAME  <<DELIM
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	ServerName $FQDN
	DocumentRoot $WWW_PATH/$GUI_NAME
	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>
	<Directory $WWW_PATH/$GUI_NAME/>
		Options Indexes FollowSymLinks MultiViews
		AllowOverride None
		Order allow,deny
		allow from all
	</Directory>

	ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
	<Directory "/usr/lib/cgi-bin">
		AllowOverride None
		Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
		Order allow,deny
		Allow from all
	</Directory>

	ErrorLog /var/log/apache2/error.log

	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn

	CustomLog /var/log/apache2/access.log combined

    Alias /doc/ "/usr/share/doc/"
    <Directory "/usr/share/doc/">
        Options Indexes MultiViews FollowSymLinks
        AllowOverride None
        Order deny,allow
        Deny from all
        Allow from 127.0.0.0/255.0.0.0 ::1/128
    </Directory>

</VirtualHost>
DELIM
			/usr/sbin/a2ensite $GUI_NAME
			/bin/cat >> /etc/apache2/conf.d/securedb.conf <<'DELIM'
#
# The following lines prevent .db files from being
# viewed by Web clients.
#
<Files ~ "^.*\.db">
    Order allow,deny
    Deny from all
    Satisfy all
</Files>
DELIM
			/etc/init.d/apache2 restart
#			/bin/sed -i -e s,"DocumentRoot /var/www","DocumentRoot /var/www/fusionpbx", \
#				-e s,"<Directory /var/www/>","<Directory /var/www/fusionpbx/>", \
#				/etc/apache2/sites-enabled/000-default

			if [ $? -ne 0 ]; then
				#previous had an error
#				/bin/echo "ERROR: Failed edit of /etc/apache2/sites-enabled/000-default"
				/bin/echo "ERROR: Failed addtion of /etc/apache2/sites-enabled/$GUI_NAME"
				exit 1
			else
#				/bin/echo "/etc/apache2/sites-enabled/000-default modified."
				/bin/echo "/etc/apache2/sites-enabled/$GUI_NAME added."
				/bin/echo "  Root www directory is now $WWW_PATH/$GUI_NAME"
			fi
		else
			/bin/echo
			#/bin/echo "/etc/apache2/sites-enabled/000-default already edited. Skipping..."
			/bin/echo "/etc/apache2/sites-enabled/$GUI_NAME already there. Skipping..."
		fi

		/bin/grep 10M /etc/php5/apache2/php.ini > /dev/null
		if [ $? -ne 0 ]; then
			/bin/sed -i -e s,"upload_max_filesize = 2M","upload_max_filesize = 10M", /etc/php5/apache2/php.ini
			if [ $? -ne 0 ]; then
				#previous had an error
				/bin/echo "ERROR: failed edit of /etc/php5/apache2/php.ini upload_max_filesize = 10M."
				exit 1
			fi
		else
			/bin/echo
			/bin/echo "/etc/php5/apache2/php.ini already edited. Skipping..."
		fi

		/bin/echo "document root for apache2 is:"
		/bin/echo "  $WWW_PATH/$GUI_NAME"
		/bin/echo "  php has an upload file size limit of 10 MegaBytes"
		/bin/echo
		/bin/echo "now install FusionPBX. This should go fast."
		/bin/echo
	;;
	#-----------------
	# Apache Done
	#-----------------


	#-----------------
	# NGINX
	#-----------------
	*)
	#elif [ $APACHENGINX == "n" ] || [ $APACHENGINX == "N" ] || [ $APACHENGINX == "" ]; then
	# ^ would be almost there. empty read isn't caught. switching to case. more flexible...
		if [ -e /usr/sbin/apache2 ]; then
			#apache2 is installed.
			/bin/echo
			/bin/echo "Apache2 is installed, and you selected nginx/php5-fpm."
			if [ $DEBUG -eq 1 ]; then
				/bin/echo
				/bin/echo "  We need to remove apache2, and php5. The packages"
				/bin/echo "  are not purged, so configuration files will stay."
				/bin/echo
				/bin/echo "  Do you want to remove apache2/php5 and install "
				read -p "    nginx/php5-fpm (y/n)? " YESNO
			else 
				YESNO=y
			fi
				case "$YESNO" in 
					[Yy]*)
						#remove packages
						/usr/bin/apt-get -y remove apache2 apache2-mpm-prefork apache2-utils apache2.2-bin \
						  apache2.2-common libapache2-mod-php5 libapr1 libaprutil1 libaprutil1-dbd-sqlite3 \
						  libaprutil1-ldap ssl-cert
						  
						/bin/echo "  APACHE2 REMOVED!"
						#removing libapr removes subversion!
						/usr/bin/apt-get -y install subversion
					;;
					*)
						/bin/echo "OK. We'll stop. Exiting!"
						exit 1
					;;
				esac
		fi
		
		if [ $DISTRO = "squeeze" ]; then
			#setup debian repos for nginx/php5-fpm
			/bin/echo "adding dotdeb repository for php5-fpm and nginx"
			/bin/echo "deb http://packages.dotdeb.org squeeze all" > /etc/apt/sources.list.d/squeeze-dotdeb.list
			/usr/bin/wget -O /tmp/dotdeb.gpg http://www.dotdeb.org/dotdeb.gpg 
			/bin/cat /tmp/dotdeb.gpg | apt-key add - 
			/bin/rm /tmp/dotdeb.gpg
			/usr/bin/apt-get update
		elif [ $DISTRO = "precise" ]; then
			#included in main repo we have nginx [nginx-full] and php5-fpm
			echo "already in 12.04 LTS [precise], nothing to add."
		else
			#add-apt-repository ppa:brianmercer/php  // apt-get -y install python-software-properties	
			#Add php5-fpm ppa to the list
			/bin/grep brianmercer /etc/apt/sources.list > /dev/null
			if [ $? -eq 0 ]; then
				/bin/echo "php-fpm ppa already add the old way. Fixing"
				/bin/sed -i -e s,'deb http://ppa.launchpad.net/brianmercer/php/ubuntu lucid main',, /etc/apt/sources.list
				/usr/bin/apt-add-repository ppa:brianmercer/php
			elif [ ! -e /etc/apt/sources.list.d./brianmercer-php-lucid.list ]; then
				/bin/echo "Adding PPA for php-fpm"
				#/bin/echo "deb http://ppa.launchpad.net/brianmercer/php/ubuntu lucidmain" >> /etc/apt/sources.list
				#/usr/bin/apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8D0DC64F
				/usr/bin/apt-add-repository ppa:brianmercer/php
			else
				/bin/echo "php-fpm ppa already added."
			fi

			#Add NGINX-ppa to src list.
			/bin/grep nginx /etc/apt/sources.list > /dev/null
			if [ $? -ne 0 ]; then
				/bin/echo "nginx ppa already add the old way. Fixing"
				/bin/sed -i -e s,'deb http://ppa.launchpad.net/nginx/stable/ubuntu lucid main',, /etc/apt/sources.list
				/usr/bin/apt-add-repository ppa:nginx/stable
			elif [ ! -e /etc/apt/sources.list.d./nginx-stable-lucid.list ]; then 
				/bin/echo "Adding PPA for latest nginx"
				/usr/bin/apt-add-repository ppa:nginx/stable
				#/bin/echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu lucid main" >> /etc/apt/sources.list	
				#/usr/bin/apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C
			else
				/bin/echo "nginx ppa already added"
			fi
		fi

		/usr/bin/apt-get update && /usr/bin/apt-get upgrade -y
		/usr/bin/apt-get -y install nginx
			#installs libgd2-noxpm libxslt1.1 nginx nginx-full

		if [ $DISTRO = "squeeze" ]; then
			/usr/bin/apt-get -y install php5-fpm php5-common php5-gd php-pear php5-memcache php5-apc php5-sqlite
		else
			#should work for precise
			/usr/bin/apt-get -y install php5-fpm php5-common php5-gd php-pear php5-memcache php-apc
		fi

		if [ $DISTRO = "squeeze" ]; then
			PHPINIFILE="/etc/php5/fpm/php.ini"
			PHPCONFFILE="/etc/php5/fpm/php-fpm.conf"
		elif [ $DISTRO = "precise" ]; then
			PHPINIFILE="/etc/php5/fpm/php.ini"
			#also exists, but www.conf used by default...
			#PHPCONFFILE="/etc/php5/fpm/php-fpm.conf"
			#max_children set in /etc/php5/fpm/pool.d/www.conf
			PHPCONFFILE="/etc/php5/fpm/pool.d/www.conf"
		else
			PHPINIFILE="/etc/php5/fpm/php.ini"
			PHPCONFFILE="/etc/php5/fpm/php5-fpm.conf"
		fi
		/bin/grep 10M /etc/php5/fpm/php.ini > /dev/null
		if [ $? -ne 0 ]; then
			/bin/sed -i -e s,"upload_max_filesize = 2M","upload_max_filesize = 10M", $PHPINIFILE
			if [ $? -ne 0 ]; then
				#previous had an error
				/bin/echo "ERROR: failed edit of $PHPINIFILE upload_max_filesize = 10M."
				exit 1
			fi
		else
			/bin/echo
			/bin/echo "/etc/php5/fpm/php.ini already edited. Skipping..."
		fi

		##Applying fix for cgi.fix_pathinfo
		/bin/grep 'cgi\.fix_pathinfo=0' $PHPINIFILE > /dev/null
		if [ $? -ne 0 ]; then
			/bin/sed -i -e s,';cgi\.fix_pathinfo=1','cgi\.fix_pathinfo=0', $PHPINIFILE
			if [ $? -ne 0 ]; then
				/bin/echo "ERROR: failed edit of $PHPINIFILE cgi.fix_pathinfo=0"
				exit 1
			fi
		else
			/bin/echo
			/bin/echo "/etc/php5/fpm/php.ini already edited for cgi.fix_pathinfo. Skipping..."
		fi

		#We don't need so many php children. 1 per core should be fine FOR NOW.
		#/bin/sed -i -e s,"pm.max_children = 10","pm.max_children = 4", /etc/php5/fpm/php5-fpm.conf

		/bin/grep "pm.max_children = 4" $PHPCONFFILE > /dev/null
		if [ $? -ne 0 ]; then
			/bin/sed -i -e s,"pm.max_children = 10","pm.max_children = 4", $PHPCONFFILE
			if [ $? -ne 0 ]; then
				#previous had an error
				/bin/echo "ERROR: failed edit of $PHPCONFFILE pm.max_children = 4"
				exit 1
			fi
		else
			/bin/echo
			/bin/echo "$PHPCONFFILE [children] already edited. Skipping..."
		fi

		#max_servers must be <= max_children
		/bin/grep "pm.max_spare_servers = 4" $PHPCONFFILE > /dev/null
		if [ $? -ne 0 ]; then
			/bin/sed -i -e s,"pm.max_spare_servers = 6","pm.max_spare_servers = 4", $PHPCONFFILE
			if [ $? -ne 0 ]; then
				#previous had an error
				/bin/echo "ERROR: failed edit of $PHPCONFFILE pm.max_spare_servers = 4"
				exit 1
			fi
		else
			/bin/echo
			/bin/echo "pm.max_spare_servers not changed"
		fi

		#update auto-starts ###PHP5-fpm and nginx are wrong??
		update-rc.d php5-fpm enable
		/etc/init.d/php5-fpm start

		##setup niginx for fusionpbx & phpmyadmin!
		update-rc.d nginx enable
		/etc/init.d/nginx start

		#NGINX server config:

		rm /etc/nginx/sites-enabled/default

		/bin/grep '.db' /etc/nginx/sites-available/$GUI_NAME >> /dev/null
		if [ $? -ne 0 ]; then
			/bin/echo "Nginx insecure previous installation"
			/bin/echo "  allows http access to FusionPBX database"
			/bin/echo "  FIXING..."
			/bin/rm /etc/nginx/sites-available/$GUI_NAME
		fi

		if [ -a /etc/nginx/sites-available/$GUI_NAME ]; then
			/bin/echo "/etc/nginx/sites-available/$GUI_NAME already exists... skipping"
		else
			nginxconfig
		fi
		if [ $DISTRO = "lucid" ]; then
			/bin/grep fastcgi_param.*HTTPS.*\$https\; /etc/nginx/fastcgi_params
			if [ $? -eq 0 ]; then
				echo "Fixing a weird nginx fastcgi_parm issue"
				echo "  you can also add the following stanzas to"
				echo "  your /etc/nginx/sites-enabled/$GUI_NAME file"
				echo "  set $https off; #for listen 80 and listen localhost"
				echo "  set $https on; #for listen 443"
				/bin/sed -i /etc/nginx/fastcgi_params -e s/fastcgi_param.*HTTPS.*\$https\;/#fastcgi_param\ HTTPS\ \$https\;/
			fi
		fi
	;;

	esac
	#-----------------
	# NGINX Done
	#-----------------
	
	#else
	#	/bin/echo "Didn't catch that. exiting"
	#	exit 1
	#fi

	cd $WWW_PATH

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		/bin/echo "Press Enter to continue (check for errors)"
		read
	fi

	/bin/echo "Stopping FreeSWITCH..."
	#/etc/init.d/freeswitch stop
	if [[ "$INST_FPBX" == "svn" ]]; then
			if [ $FBPXCHECKOUTVER == true ]; then
				/bin/echo "Going to install FusionPBX SVN Rev $FPBXREV"
				/usr/bin/svn checkout -r r$FPBXREV http://fusionpbx.googlecode.com/svn/branches/dev/fusionpbx $WWW_PATH/$GUI_NAME
			else
				/bin/echo "Going to install FusionPBX latest SVN!"
				#removed -r r1877 r1877 from new install
				/usr/bin/svn checkout http://fusionpbx.googlecode.com/svn/trunk/fusionpbx $WWW_PATH/$GUI_NAME
			fi
	elif [ $INST_FPBX == tgz ]; then
			/bin/tar -C $WWW_PATH -xzvf $TGZ_FILE
	fi
	if [ ! -e $WWW_PATH/$GUI_NAME ]; then
		/bin/mv $WWW_PATH/fusionpbx $WWW_PATH/$GUI_NAME
	fi

	/usr/sbin/adduser freeswitch www-data
	/usr/sbin/adduser www-data daemon
	/bin/chown -R www-data:www-data $WWW_PATH/$GUI_NAME
	/bin/echo "freeswitch is now a member of the www-data group"
	/bin/echo "  www-data is now a member of the dameon group"

	/usr/bin/find $WWW_PATH/$GUI_NAME -type f -exec /bin/chmod 644 {} \;
	/usr/bin/find $WWW_PATH/$GUI_NAME -type d -exec /bin/chmod 755 {} \;

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		/bin/echo "Press Enter to continue (check for errors)"
		read
	fi

	if [ $APACHENGINX == "a" ]; then
		/etc/init.d/apache2 restart
	elif [ $APACHENGINX == "n" ]; then
		/etc/init.d/nginx restart
	fi

	/bin/echo "FusionPBX install needs Write permissions on group to remove files"
	/bin/echo "The daemon group (of which www-data is a member) can now edit all files"
	/bin/echo "  in your FreeSWITCH installation. This may or may not be desirable"
	/bin/echo 
	/bin/echo "if you want to change this, run (as root)"
	/bin/echo "  /usr/bin/find /usr/local/freeswitch -type f -exec /bin/chmod g-w {} \;"
	/bin/echo "  /usr/bin/find /usr/local/freeswitch -type d -exec /bin/chmod g-w {} \;"
	/bin/echo "  however; FusionPBX won't be able to make changes anymore"
	/usr/bin/find /usr/local/freeswitch -type f -exec /bin/chmod g+w {} \;
	/usr/bin/find /usr/local/freeswitch -type d -exec /bin/chmod g+w {} \;

#	/bin/echo "go to the web address in your browser to finish configuration"
#	/bin/echo '  http://'`/sbin/ifconfig eth0 | /bin/grep 'inet addr:' | /usr/bin/cut -d: -f2 | /usr/bin/awk '{ print $1}'`

#	/bin/echo "don't forget to start FreeSWITCH after the install!"
#	/bin/echo "/etc/init.d/freeswitch start"


	#FreeSWITCH needs read access to scripts in /var/www/fusionpbx/secure
	#per mcrane on IRC
	#mcrane: the easiest way to get it to work is have FreeSWITCH and the web server run under the same user
	# instead we made freeswitch user a member of the www-data group, and www-data user a member of the
	# daemon group.

	#added v3
	#move the default extensions .noload
	#The default FusionPBX install removes the default FreeSWITCH password, so anyone can register
	#with these default FreeSWITCH extensions.  They aren't 'in' FusionPBX anyhow, so we don't need
	#them. We will leave them for reference.
	/bin/echo "renaming default FreeSWITCH extensions .noload"
	for i in /usr/local/freeswitch/conf/directory/default/1*.xml;do mv $i $i.noload ; done


	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		/bin/echo "Press Enter to continue (check for errors)"
		read
	fi

	/bin/echo
	/bin/echo "Finishing Up FusionPBX installation."
	/bin/echo "Now for a database..."
	/bin/echo


	#-----------------
	# MySQL
	#-----------------
	#Lets ask... sqlite or mysql -- for user option only
	if [ $DEBUG -eq 1 ]; then
		/bin/echo "New Option..."
		/bin/echo "  SQlite is already installed (and required)"
		/bin/echo
		read -p "  Would you like to install MySQL, PostgreSQL or stay with Sqlite (m/p/S)? " SQLITEMYSQL
		case "$SQLITEMYSQL" in
		  [pP]*)
			if [ $DISTRO = "precise" ]; then
				echo "precise is PostgreSQL 9.1 by default"
				POSTGRES9=9
			else
				/bin/echo
				/bin/echo "OK, PostgreSQL! Would you prefer the stock verion 8.4"
				/bin/echo "  or verion 9 from PPA?"
				/bin/echo
				read -p "PostgreSQL 8.4 or 9 [8/9]? " POSTGRES9 
			fi
			echo
		  ;;
		esac
	fi

	case "$SQLITEMYSQL" in
	[Mm]*)
	#if [ $SQLITEMYSQL == "m" ]; then
		/bin/echo "Installing MySQL"
		/usr/bin/apt-get -y install mysql-server php5-mysql mysql-client
		if [ -e /usr/sbin/nginx ]; then
			#nginx is installed.
			/etc/init.d/php5-fpm restart
			/etc/init.d/nginx restart
		elif [ -e /usr/sbin/apache2 ]; then
			#apache2 is installed.
			/etc/init.d/apache2 restart
		fi
		/bin/echo "Now you'll need to manually finish the install and come back"
		/bin/echo "  This way I can finish up the last bit of permissions issues"
		/bin/echo "  Just go to"
		/bin/echo '  http://'`/sbin/ifconfig eth0 | /bin/grep 'inet addr:' | /usr/bin/cut -d: -f2 | /usr/bin/awk '{ print $1}'`
		/bin/echo "       MAKE SURE YOU CHOOSE MYSQL as your Database on the first page!!!"
		/bin/echo "       ON the Second Page:"
		/bin/echo "          Create Database Username: root"
		/bin/echo "          Create Database Password: the_pw_you_set_during_install"
		/bin/echo "			 other options: whatever you like"
		/bin/echo "  I will wait here until you get done with that."
		/bin/echo -ne "  When MySQL is configured come back and press enter. "
		read
	;;

	[Pp]*)
	#elif [ $SQLITEMYSQL == "p" ]; then	
		/bin/echo -ne "Installing PostgeSQL"

		if [ $POSTGRES9 == "9" ]; then
			/bin/echo " version 9.1"
			if [ $DISTRO = "squeeze" ]; then
				#add squeeze repo
				/bin/echo "Adding debian backports for postgres9.1"
				/bin/echo "deb http://backports.debian.org/debian-backports squeeze-backports main" > /etc/apt/sources.list.d/squeeze-backports.list
				/usr/bin/apt-get update
				/usr/bin/apt-get -y -t squeeze-backports install postgresql-9.1 php5-pgsql
			elif [ $DISTRO = "precise" ]; then
				#already there...
				/usr/bin/apt-get -y install postgresql-9.1 php5-pgsql
			else
				#add the ppa
				/usr/bin/apt-add-repository ppa:pitti/postgresql
				/usr/bin/apt-get update
				/usr/bin/apt-get -y install postgresql-9.1 php5-pgsql
			fi
		else
			/bin/echo " version 8.4"
			/usr/bin/apt-get -y install postgresql php5-pgsql
			#The following NEW packages will be installed:
			#  libpq5 php5-pgsql postgresql postgresql-8.4 postgresql-client-8.4
			#  postgresql-client-common postgresql-common
		fi

		/bin/su -l postgres -c "/usr/bin/createuser -s -e $GUI_NAME"
		#/bin/su -l postgres -c "/usr/bin/createdb -E UTF8 -O $GUI_NAME $GUI_NAME"
		/bin/su -l postgres -c "/usr/bin/createdb -E UTF8 -T template0 -O $GUI_NAME $GUI_NAME"
		PGSQLPASSWORD="dummy"
		PGSQLPASSWORD2="dummy2"
		while [ $PGSQLPASSWORD != $PGSQLPASSWORD2 ]; do
		/bin/echo
		/bin/echo
		/bin/echo "THIS PROBABLY ISN'T THE MOST SECURE THING TO DO."
		/bin/echo "IT IS; HOWEVER, AUTOMATED. WE ARE STORING THE PASSWORD"
		/bin/echo "AS A BASH VARIABLE, AND USING ECHO TO PIPE IT TO"
		/bin/echo "psql. THE COMMAND USED IS:"
		/bin/echo
		/bin/echo "/bin/su -l postgres -c \"/bin/echo 'ALTER USER $GUI_NAME with PASSWORD \$PGSQLPASSWORD;' | psql $GUI_NAME\""
		/bin/echo
		/bin/echo "AFTERWARDS WE OVERWRITE THE VARIABLE WITH RANDOM DATA"
		/bin/echo
		/bin/echo "The pgsql username is $GUI_NAME"
		/bin/echo "The pgsql database name is $GUI_NAME"
		/bin/echo "Please provide a password for the $GUI_NAME user"
		#/bin/stty -echo
		read -s -p "  Password: " PGSQLPASSWORD
		/bin/echo
		/bin/echo "Let's repeat that"
		read -s -p "  Password: " PGSQLPASSWORD2
		/bin/echo
		#/bin/stty echo
		done

		/bin/su -l postgres -c "/bin/echo \"ALTER USER $GUI_NAME with PASSWORD '$PGSQLPASSWORD';\" | /usr/bin/psql $GUI_NAME"
		/bin/echo "overwriting pgsql password variable with random data"
		PGSQLPASSWORD=$(/usr/bin/head -c 512 /dev/urandom)
		PGSQLPASSWORD2=$(/usr/bin/head -c 512 /dev/urandom)

		if [ -e /usr/sbin/nginx ]; then
			#nginx is installed.
			/etc/init.d/php5-fpm restart
			/etc/init.d/nginx restart
		elif [ -e /usr/sbin/apache2 ]; then
			#apache2 is installed.
			/etc/init.d/apache2 restart
		fi
		/bin/echo "Now you'll need to manually finish the install and come back"
		/bin/echo "  This way I can finish up the last bit of permissions issues"
		/bin/echo "  Just go to"
		/bin/echo '  http://'`/sbin/ifconfig eth0 | /bin/grep 'inet addr:' | /usr/bin/cut -d: -f2 | /usr/bin/awk '{ print $1}'`
		/bin/echo "       MAKE SURE YOU CHOOSE PostgreSQL as your Database on the first page!!!"
		/bin/echo "       ON the Second Page:"
		/bin/echo "          Database Name: $GUI_NAME"
		/bin/echo "          Database Username: $GUI_NAME"
		/bin/echo "          Database Password: whateveryouentered"
		/bin/echo "          Database Username: Leave_Blank (remove pgsql)"
		/bin/echo "          Create Database Password: Leave_Blank"
		/bin/echo 
		/bin/echo "  I will wait here until you get done with that."
		/bin/echo -ne "  When PostgreSQL is configured come back and press enter. "
		read
	;;
	*)
	#elif [ $SQLITEMYSQL == "s" || $SQLITEMYSQL == "S" || $SQLITEMYSQL == "" ]; then
		/bin/echo "SQLITE is chosen. already done. nothing left to install..."
		if [ -e /usr/sbin/nginx ]; then
			#nginx is installed.
			/etc/init.d/php5-fpm restart
			/etc/init.d/nginx restart
		elif [ -e /usr/sbin/apache2 ]; then
			#apache2 is installed.
			/etc/init.d/apache2 restart
		fi
		#with $GUI_NAME in there, it's really hosing things up and how.
#		/usr/bin/curl -s -d "db_type=sqlite&install_switch_base_dir=%2Fusr%2Flocal%2Ffreeswitch&install_php_dir=%2Fvar%2Fwww%2F$GUI_NAME&install_tmp_dir=%2Ftmp&install_backup_dir=%2Ftmp&install_step=2&submit=Next" http://localhost/install.php > /dev/null
#		/usr/bin/curl -s -d "db_filename=$GUI_NAME.db&db_filepath=%2Fvar%2Fwww%2F$GUI_NAME%2Fsecure&db_type=sqlite&install_secure_dir=%2Fvar%2Fwww%2F$GUI_NAME%2Fsecure&install_switch_base_dir=%2Fusr%2Flocal%2Ffreeswitch&install_php_dir=%2Fvar%2Fwww%2F$GUI_NAME&install_tmp_dir=%2Ftmp&install_backup_dir=%2Ftmp&install_step=3&submit=Next" http://localhost/install.php > /dev/null

		#do for https too!
#		/usr/bin/curl -k -s -d "db_type=sqlite&install_switch_base_dir=%2Fusr%2Flocal%2Ffreeswitch&install_php_dir=%2Fvar%2Fwww%2F$GUI_NAME&install_tmp_dir=%2Ftmp&install_backup_dir=%2Ftmp&install_step=2&submit=Next" https://localhost/install.php > /dev/null
#		/usr/bin/curl -k -s -d "db_filename=$GUI_NAME.db&db_filepath=%2Fvar%2Fwww%2F$GUI_NAME%2Fsecure&db_type=sqlite&install_secure_dir=%2Fvar%2Fwww%2F$GUI_NAME%2Fsecure&install_switch_base_dir=%2Fusr%2Flocal%2Ffreeswitch&install_php_dir=%2Fvar%2Fwww%2F$GUI_NAME&install_tmp_dir=%2Ftmp&install_backup_dir=%2Ftmp&install_step=3&submit=Next" https://localhost/install.php > /dev/null

		/bin/echo "FusionPBX install.php was done automatically"
		/bin/echo "  when sqlite was selected. "
		/bin/echo "  FreeSWITCH Directory: /usr/local/freeswitch"
		/bin/echo "  PHP Directory: $WWW_PATH/$GUI_NAME"
		/bin/echo
		/bin/echo "  Database Filename: $GUI_NAME.db"
		/bin/echo "  Database Directory: $WWW_PATH/$GUI_NAME/secure"
		/bin/echo
		/bin/echo "  Just go to"
		/bin/echo '  http://'`/sbin/ifconfig eth0 | /bin/grep 'inet addr:' | /usr/bin/cut -d: -f2 | /usr/bin/awk '{ print $1}'`	
		/bin/echo
		/bin/echo "Default login is (whatever you picked in the GUI install):"
		/bin/echo "  User: WhateverUsernameYouPicked"
		/bin/echo "  Passwd: YourPasswordYouPicked"
	;;
	esac
	#else
	#	/bin/echo "Didn't catch that. exiting"
	#	exit 1
	#fi

	finish_fpbx_install_permissions
	#/bin/echo
	#/bin/echo "The FusionPBX installation messed up permissions of /usr/local/freeswitch/storage"
	#/bin/echo "   Fixing..."
#	read
	#/usr/bin/find /usr/local/freeswitch -type f -exec /bin/chmod g+w {} \;
	#/usr/bin/find /usr/local/freeswitch -type d -exec /bin/chmod g+w {} \;

	#/bin/echo "Starting FreeSWITCH..."
	#/etc/init.d/freeswitch start
	/bin/echo "Setting up Fail2Ban for FusionPBX"
	fusionfail2ban
	/etc/init.d/fail2ban restart

	/bin/echo
	/bin/echo
	/bin/echo "Installation Completed.  Now configure FreeSWITCH via the FusionPBX browser interface"
	/bin/echo
	/bin/echo '  http://'`/sbin/ifconfig eth0 | /bin/grep 'inet addr:' | /usr/bin/cut -d: -f2 | /usr/bin/awk '{ print $1}'`
	/bin/echo "Default login is (whatever you picked in the GUI install):"
	/bin/echo "  User: WhateverUsernameYouPicked"
	/bin/echo "  Passwd: YourPasswordYouPicked"

fi
#------------------------------------
#    DONE INSTALLING FUSIONPBX
#------------------------------------


#------------------------------------
#       UPGRADE FREESWITCH
#------------------------------------

if [ $UPGFREESWITCH -eq 1 ]; then

	#------------------------
	# build modules.conf 
	#------------------------
	/bin/grep 'build_modules' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "Modules.conf Already edited"	
	else
		#file exists and has been edited
		build_modules
		#check exit status
		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "ERROR: Failed to enable build modules in modules.conf."
			exit 1
		else
			/bin/echo "build_modules" >> /tmp/install_fusion_status
		fi
	fi
	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		/bin/echo "Press Enter to continue (check for errors)"
		read
	fi

	#------------------------
	# make current 
	#------------------------
	/bin/grep 'made_current' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "Modules.conf Already edited"	
	else
		/bin/echo
		/bin/echo ' going to run make curent'
		/bin/echo "   Make current completely cleans the build environment and rebuilds FreeSWITCH™"
		/bin/echo "   so it runs a long time. However, it will not overwrite files in a pre-existing"
		/bin/echo '   "conf" directory. Also, the clean targets leave the "modules.conf" file.'
		/bin/echo "   This handles the git pull, cleanup, and rebuild in one step"
		/bin/echo '       src: http://wiki.freeswitch.org/wiki/Installation_Guide'
		cd /usr/src/freeswitch
		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "/usr/src/freeswitch does not exist"
			/bin/echo "you probably installed from a FusionPBX ISO which deleted this"
			/bin/echo "Directory to save space.  rerun with install-freeswitch option"
			exit 1
		fi
		cd /usr/src/freeswitch

		#get on the 1.2.x release first...
		echo
		echo
		echo "Checking to see which version of FreeSWITCH you are on"
		git status |grep "1.2"
		if [ $? -ne 0 ]; then
			echo "It appears that you are currently on the FreeSWITCH Git Master branch, or no branch."
			echo "  We currently recommend that you switch to the 1.2.x branch,"
			echo "  since 1.4 [master] may not be very stable."
			echo
			read -p "Shall we change to the 1.2.x branch [Y/n]? " YESNO
		else
			YESNO="no"
		fi

		case $YESNO in
				[Nn]*)
						echo "OK, staying on current...."
						FSSTABLE=false
				;;

				*)
						echo "OK, switching to 1.2.x."
						FSSTABLE=true
				;;
		esac

		if [ $FSSTABLE == true ]; then
			echo "OK we'll now use the 1.2.x stable branch"
			cd /usr/src/freeswitch
			
			#odd edge case, I think from a specific version checkout
				# git status
				# Not currently on any branch.
				# Untracked files:
				#   (use "git add <file>..." to include in what will be committed)
				#
				#       src/mod/applications/mod_httapi/Makefile

			git status |grep -i "not currently"
			if [ $? -eq 0 ]; then
				echo "You are not on master branch.  We have to fix that first"
				/usr/bin/git checkout master
				if [ $? -ne 0 ]; then
					#git checkout had an error
					/bin/echo "GIT CHECKOUT to 1.2.x ERROR"
					exit 1
				fi
			fi

			#/usr/bin/time /usr/bin/git clone -b $FSStableVer git://git.freeswitch.org/freeswitch.git
			/usr/bin/git pull
			if [ $? -ne 0 ]; then
				#git checkout had an error
				/bin/echo "GIT PULL to 1.2.x ERROR"
				exit 1
			fi
			/usr/bin/git checkout $FSStableVer
			if [ $? -ne 0 ]; then
				#git checkout had an error
				/bin/echo "GIT CHECKOUT to 1.2.x ERROR"
				exit 1
			fi
			#/usr/bin/git checkout master
			#if [ $? -ne 0 ]; then
			#	#git checkout had an error
			#	/bin/echo "GIT CHECKOUT to 1.2.x ERROR"
			#	exit 1
			#fi

		else
			echo "staying on dev branch.  Hope this works for you."
		fi

		cd /usr/src/freeswitch
		echo "reconfiguring mod_spandsp"
		make spandsp-reconf

		if [ $CORES > "1" ]; then 
			/bin/echo "  multicore processor detected. Upgrading with -j $CORES"
			/usr/bin/time /usr/bin/make -j $CORES current
		else 
			/bin/echo "  singlecore processor detected. Starting upgrade sans -j"
			/usr/bin/time /usr/bin/make current
		fi
		#/usr/bin/make current
		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "make current error"
			exit 1
		fi

		if [ $DEBUG -eq 1 ]; then
			/bin/echo
			/bin/echo "I'm going to stop here and wait.  FreeSWITCH has now been compiled and is ready to install"
			/bin/echo "but in order to do this we need to stop FreeSWITCH [which will dump any active calls]."
			/bin/echo "This should not take too long to finish, but we should try and time things correctly."
			/bin/echo "The current status of your switch is:"
			/bin/echo
			/usr/local/freeswitch/bin/fs_cli -x status
			/bin/echo
			/bin/echo -n "Press Enter to continue the upgrade."
			read
		fi

		/etc/init.d/freeswitch stop
		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "Init ERROR, couldn't stop Freeswitch"
			exit 1
		fi
		/usr/bin/make install
		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "INSTALL ERROR!"
			exit 1
		else 
			/bin/echo "made_current" >> /tmp/install_fusion_status
		fi
	fi

	#------------------------
	# enable modules.conf.xml
	#------------------------
	/bin/grep 'enable_modules' /tmp/install_fusion_status > /dev/null
	if [ $? -eq 0 ]; then
		/bin/echo "Modules.conf.xml Already enabled"
	else
		#file exists and has been edited
		enable_modules
		#check exit status
		if [ $? -ne 0 ]; then
			#previous had an error
			/bin/echo "ERROR: Failed to enable modules in modules.conf.xml."
			exit 1
		else
			/bin/echo "enable_modules" >> /tmp/install_fusion_status
		fi
	fi

	if [ $DEBUG -eq 1 ]; then
		/bin/echo
		/bin/echo "Press Enter to continue (check for errors)"
		read
	fi

	#check for logrotate and change to cron.daily
	if [ -a /etc/logrotate.d/freeswitch ]; then
		/bin/echo "System configured for logrotate, changing"
		/bin/echo "   to new way."
		/bin/rm /etc/logrotate.d/freeswitch
		/etc/init.d/logrotate restart
		freeswitch_logfiles
	fi

	if [ -e $WWW_PATH/$GUI_NAME ]; then
		echo "I noticed that FusionPBX is installed too"
		echo "now going to fix freeswitch permissions from upgrade to be safe"
		www_permissions
	else
		echo "Standalone FreeSWITCH installation, no permissions to change"
	fi
	/etc/init.d/freeswitch start
fi
#------------------------------------
#    DONE UPGRADING FREESWITCH
#------------------------------------


#------------------------------------
#       UPGRADE FusionPBX
#------------------------------------

if [ $UPGFUSION -eq 1 ]; then
	/bin/echo "Resetting FreeSWITCH permissions to www-data in case you did"
	/bin/echo "  a FreeSWITCH upgrade as well."
	www_permissions
	cd $WWW_PATH/$GUI_NAME
	/bin/echo
	/bin/echo "STOP! Make sure you are logged into fusionpbx as the superadmin (via browser)!!!"
	read -p "Have you done this yet (y/n)? " YESNO
	if [ $YESNO == "y" ]; then
		/bin/echo "Be really sure you are logged in as superadmin."
		/bin/echo "  If nothing else, refresh the browser to make sure"
		/bin/echo "  the session isn't stale."
		/bin/echo 
		/bin/echo "If you haven't done this you risk not being able to Upgrade->Schema"
		/bin/echo "  which will toast your database"
		/bin/echo

		FUSIONREV=$(svn info $WWW_PATH/$GUI_NAME |grep -i revision|sed -e s/Revision:\ //)
		if [ $FUSIONREV -le 1877 ]; then
			echo "The project is still working on an upgrade tool"
			echo "    for the latest svn version.  It is recommended"
			echo "    that you stay with revision 1877.  Your current"
			echo "    revision is $FUSIONREV"
			echo
			read -p "Do we want Revision 1877, or latest (1877/latest)? " YESNO2
		else
				read -p "Ready to upgrade (y/n)? " YESNO2
		fi

		case $YESNO2 in 

		[YylL]*)

			#svn...

			/usr/bin/svn update http://fusionpbx.googlecode.com/svn/branches/dev/fusionpbx $WWW_PATH/$GUI_NAME
			/bin/chown -R www-data:www-data $WWW_PATH/$GUI_NAME
			#print message saying to hit advanced->upgrade schema
			/bin/echo "Done upgrading Files"
			/bin/echo "For the Upgrade to finish you MUST login to FusionPBX as superadmin"
			/bin/echo "and select Advanced -> Upgrade Schema"
		;;

		[1]*)
			/usr/bin/svn update -r r1877 http://fusionpbx.googlecode.com/svn/trunk/fusionpbx $WWW_PATH/$GUI_NAME
			/bin/chown -R www-data:www-data $WWW_PATH/$GUI_NAME
			#print message saying to hit advanced->upgrade schema
			/bin/echo "Done upgrading Files"
			/bin/echo "For the Upgrade to finish you MUST login to FusionPBX as superadmin"
			/bin/echo "and select Advanced -> Upgrade Schema"
		;;
		*)
			echo "Bad option, exiting"
			exit 1
		;;
		esac
	else
		exit 1
	fi
	read -p "Do you want to try and run the auto-upgrade php script from CLI (y/n)? " YESNO
	case $YESNO in
	[yY]*)
			echo "Starting... /usr/bin/php $WWW_PATH/$GUI_NAME/core/upgrade/upgrade.php"
			/usr/bin/php $WWW_PATH/$GUI_NAME/core/upgrade/upgrade.php
			echo "Done"
	;;
	*)
		echo "OK, don't forget to run it yourself via gui or here with"
		echo "    /usr/bin/php $WWW_PATH/$GUI_NAME/core/upgrade/upgrade.php"
	;;
	esac
	fusionfail2ban
fi
#------------------------------------
#    DONE UPGRADING FusionPBX
#------------------------------------

#success!!!
if [ -e /tmp/install_fusion_status ]; then
	/bin/rm /tmp/install_fusion_status
fi

/bin/echo "Checking to see if FreeSWITCH is running!"
/usr/bin/pgrep freeswitch
if [ $? -ne 0 ]; then
	/etc/init.d/freeswitch start
else
	/bin/echo "    DONE!"
fi

exit 0

---------
#CHANGELOG
#---------
# vSVN, now using SVN.... November 2011

#v4.4.0pre 2011 April 12

#BUGS: FS CHANGED!!! 2011-05-12
#		Add libssl-dev
#		currently mod_cidlookup, mod_xml_curl mod_xml_cdr busted

#BUGS: FS isn't  started at end of install-both auto
#BUGS: fix-https still throws usage help. check www-permissions too.
#BUGS: Apache heredoc isn't escaping the variables. documentroot and servername wrong.
#BUGS: dingaling still not compile right. let's change makefile and recompile module
#ADD: zip compression to nginx
#ADD: monit for freeswitch and nginx
#add libssl-dev for secure sip.

#	ADD mod_spandsp for fax and g722
#		apt-get install libtiff4-dev
#	Add NTP, maybe run sudo ntpdate ntp.ubuntu.com to make suer date is correct.
# 		prevents make from dying (date in the future crap).
#	BUGS: Had quotes around nginx config
#			FS failed to start with script
#			Fail2Ban FS-dos has freeswitch2 in jail.local
#			Fail2ban not starting: 
#			freeswitch-dos ports wrong in jail.local.
#				build again and run fail2ban-client -d to test.
#   Add Option to download FreeSWITCH compiled source as tar.gz for iso
#   Added Option --fix-permissions
#		checks FreeSWITCH init script 
#	Added: upgrade-fusionpbx needs to fix permissions, since a FS upgrade kills them.
#	FIXED Logrotate for nginx
#		logfiles were: /var/log/fusionpbx_gui.*_log;
#		logfiles now: /var/log/nginx/*.log
#	Added: Fail2ban for FusionPBX failed login attempts
#		Need information on attempts/rate/etc 
#	Added: Fail2ban for FusionPBX on failed provision attempts
#		Need information on attempts/rate/etc 
#		Needs Testing!
#	FIXED: RepeatedMsgReduction wasn't getting set correctly in rsyslog.conf
#	Added Change Fail2ban on FreeSWITCH with attempts/rate/etc in config file (not default settings)
#	Added: Option to download GIT from GitHub repository (It's faster), see DEFINES

#	Make nginx/apache https by default
#		iso needs to regenerate certificates post install, ideally with 10 year expirations. 
#		apt-get install ssl-cert
#		ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/nginx.key
#		ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/nginx.crt
#		ln -s /etc/ssl/certs/nginx.crt /var/www/fusionpbx/$HOSTNAME.crt
#		/etc/init.d/nginx restart
		
#	FIXED nginx config to not block html files... Don't do block ~ .ht 
#	Added FreeTDM, and Dahdi

#v4.3.3 2011 January 31
#	Added: smp compile support. Script works, make -j doesn't. see jira FS-3005
#	Fixed: NGinx file size error
#	Added: Remove Nginx/php/apache properly
#		FIXED removing nginx removes gnome/x.
#	Added: Postgres (seems good)
#	Fixed: Set up apache properly (fusionpbx file instead of default, use heredoc)
#   	TODO: look into setting up FS for mysql/pgsql
#   	Fixed: sqlite http request issue for nginx/apache
#   	Added: now doing ppa's the ubuntu way with apt-add-repository
#   	Added: set up auto install for nginx/apache, mysql/postgresql/sqlite, setnonat.
#	Added: now prompts for rm -Rf /opt (or variable for auto-install).
#	There's a bug in either ppa-purge or apt-add-repository (likely latter).
#	  if you install nginx, change your mind, install apache, change your mind again
#	  and re-install nginx, the repository for nginx/php5-fpm gets removed proerly
#	  [a '#' covers repo], but when re-enabling, the '#' gets replaced, and an 'n'
#	  is left on a newline afterward, preventing update/install from that repo.
#	Fixed: Checking for nginx/apache2 binary instead of init scripts for if[x] restart

#v4.3.2.1 2011 January 1
#	small problem when selecting nginx and sqlite. php5-fpm needed to restart
#	 so FusionPBX could see the FreeSWITCH directory.
#v4.3.2 2010 December 30
#	logrotate was improperly setup. Needed to send sighup to fs_cli
#	  Caused FS to die the first time it tried to log after rotation.
#	php5-cli is a dependancy. required for voicemail to email, and fax to email.
#	added an nginx/php-fpm option.  You can change a variable (for auto run)
#	  or it will prompt you when you install fusionpbx in user mode
#	mysql added as an option.
#	problem with the way ubuntu logs ssh failures [fail2ban]
#	  Failed password for root from 1.2.3.4 port 22 ssh2
#	  last message repeated 5 times
#	  SOLUTION: Turn off RepeatedMsgReduction in rsyslog.
#	fail2ban: previous setup looked for freeswitch log in /var/log/freeswitch.log
#	  log is actually /usr/local/freeswitch/log/freeswitch.log
#	Tries to see if you're on a static IP address. If you are, it wants to start
#	  FreeSWITCH with the -nonat option to save some time. Also a new variable
#	TODO: Maybe probe cores and to the -b thing for quicker compile/bootstrap
#	TODO: IPTABLES
	
#v4.3.1 2010 December 23
#	look into make -j cores option
#	made a state save file.  so if there's an error, don't re-bootstrap, configure, etc.
#	  and remove it on a clean exit.
#	requests for modules add/enable for ugrade-freeswitch. DONE
#	mod dingaling needs libgnutls-dev libgnutls26 packages, and change: 
#	  "--mode=relink gcc" --> "--mode=relink gcc -lgnutls" 
#	  in /usr/src/freeswitch/src/mod/endpoints/mod_dingaling/mod_dingaling.la
#	  appears to be an ubuntu problem....

#v4.3 2010 December 22
#	under case upgrade-freeswitch, variables were not set properly.  It upgraded fusionpbx.. fixed.
#	done: fail2ban error fixed. removed associated text
#	done: have install check for /etc/fail2ban. reinstall (as in from iso) duplicates some txt
#	done: remove or fix fusionpbx upgrade code. it either needs to log in
#	  and then update and run the schema upgrade. or get rid of it. Fixed by prompting the user
#	  to open a browser window, and warn.
#	done: get logrotate working... let's not fill the disk.
#	stop/start freeswitch for an upgrade, and an install...

#v4.2 2010 December 17
#	made some changes so the text flows correctly now that we use curl
#   to do install.php.  
#   sent curl output to dev null..
#   added apt-get update before we install apache since remastersys removes apt data
#   stopping FS before FusionPBX install, and starting afteward.
#   changed license to WAF v1

#v4.1 2010 December 15
#   changing cd sounds (48/32/16/8khz) down to hd sounds (16/8Kkhz)

#v4 2010 December 14
#   now install-fusion|install-freeswitch|upgrade...
#   also adding curl commands to finish fusionpbx install.

#v3 adding fail2ban et al.

#v2 2010 December 07
#   adds arrays to process the modules.  should make this much easier to edit.
#	just make additions to modules_add
#	This should work fine (even on a 2nd run).

#v1 2010 December 06
# was first cut
