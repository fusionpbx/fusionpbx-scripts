###### Fedora Server 22 x86_64 fusionpbx deployment script.
==========================================================

###### Assumptions:
  1. Fedora 22 Server machine is installed and dnf update with reboot ran OK.
  2. In case of multi server ssh key installed and configured for inter host communication.
  3. Script need run as root only.
  4. Internet connection is configured.

###### Usage:
  1. Download scripts.
  2. Place CertMng into /usr/bin and set +x permissions.
  3. Make sure function file in same directory as install script prefer /root
  4. Run script ./deploy_fusionpbx_fedora_server22
  5. Provide answers on asked questions.

###### Installation Model:
   1. Database and fusionpbx on same host.
   2. Database and fusionpbx on separate hosts.
  
