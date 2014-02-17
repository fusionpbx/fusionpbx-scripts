#!/bin/bash
#
#Fusionpbx repo (stable/devel)
echo ' This script will upgrade you to the new fusionpbx pkgs '
echo ' Removing Old FusionPBX Pkg '
apt-get remove fusionpbx fusionpbx-dev

#updating repo 
echo 'installing updated repo info into apt'
echo 'installing fusionpbx  repo'
/bin/cat > "/etc/apt/sources.list.d/fusionpbx.list" <<DELIM
deb http://repo.fusionpbx.com/deb-dev/debian/ wheezy main
DELIM

apt-get update

echo ' Installing New Fusionpbx pkgs'
echo " Installing fusipnpbx full install"

for i in fusionpbx-core fusionpbx-provisioning-template-aastra fusionpbx-provisioning-template-cisco fusionpbx-provisioning-template-grandstream \
		fusionpbx-provisioning-template-linksys fusionpbx-provisioning-template-panasonic fusionpbx-provisioning-template-polycom \
		fusionpbx-provisioning-template-snom fusionpbx-provisioning-template-yealink \
		fusionpbx-theme-accessible fusionpbx-theme-classic fusionpbx-theme-default fusionpbx-theme-enhanced fusionpbx-theme-nature \
		fusionpbx-app-adminer fusionpbx-app-call-block fusionpbx-app-call-broadcast fusionpbx-app-call-center fusionpbx-app-call-center-active \
		fusionpbx-app-call-flows fusionpbx-app-calls fusionpbx-app-calls-active fusionpbx-app-click-to-call fusionpbx-app-conference-centers fusionpbx-app-conferences \
		fusionpbx-app-conferences-active fusionpbx-app-contacts fusionpbx-app-content fusionpbx-app-destinations fusionpbx-app-devices fusionpbx-app-dialplan \
		fusionpbx-app-dialplan-inbound fusionpbx-app-dialplan-outbound fusionpbx-app-edit fusionpbx-app-exec fusionpbx-app-extensions fusionpbx-app-fax \
		fusionpbx-app-fifo fusionpbx-app-fifo-list fusionpbx-app-follow-me fusionpbx-app-gateways fusionpbx-app-hot-desking fusionpbx-app-ivr-menu \
		fusionpbx-app-login fusionpbx-app-log-viewer fusionpbx-app-meetings fusionpbx-app-modules fusionpbx-app-music-on-hold fusionpbx-app-park \
		fusionpbx-app-provision fusionpbx-app-recordings fusionpbx-app-registrations fusionpbx-app-ring-groups fusionpbx-app-schemas fusionpbx-app-services \
		fusionpbx-app-settings fusionpbx-app-sip-profiles fusionpbx-app-sip-status fusionpbx-app-sql-query fusionpbx-app-system fusionpbx-app-time-conditions \
		fusionpbx-app-traffic-graph fusionpbx-app-vars fusionpbx-app-voicemail-greetings fusionpbx-app-voicemails fusionpbx-app-xml-cdr fusionpbx-app-xmpp

do apt-get -y --force-yes install "${i}"
done

cd /usr/share/nginx/www/fusionpbx

php /usr/share/nginx/www/fusionpbx/core/upgrade/upgrade.php

echo ' upgrade to new fusion pkgs is complete '