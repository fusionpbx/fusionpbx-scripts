#!/bin/bash
if [ -d /usr/local/freeswitch/sounds/music/default ]; then
mv /usr/local/freeswitch/sounds/music/default /usr/local/freeswitch/sounds/music/default-custom
fi
if [ -d /usr/local/freeswitch/sounds/music/8000 ]; then
mkdir /usr/local/freeswitch/sounds/music/default
mv /usr/local/freeswitch/sounds/music/8000 /usr/local/freeswitch/sounds/music/default
mv /usr/local/freeswitch/sounds/music/16000 /usr/local/freeswitch/sounds/music/default
mv /usr/local/freeswitch/sounds/music/32000 /usr/local/freeswitch/sounds/music/default
mv /usr/local/freeswitch/sounds/music/48000 /usr/local/freeswitch/sounds/music/default
chown -R www-data:www-data /usr/local/freeswitch/sounds/music/default
fi