#!/bin/bash
cat > "/etc/apt/sources.list.d/freeswitch.list" <<DELIM
deb http://repo.fusionpbx.com/freeswitch-armhf/head/debian/ wheezy main
DELIM

cat > "/etc/apt/sources.list.d/fusionpbx.list" << DELIM
deb http://repo.fusionpbx.com/fusionpbx/head/debian/ wheezy main
DELIM