#!/bin/bash
#
#Izoox.com
#David Scalf 
#Izoox Ansible AWX Master Install
#Installs all prerequisites for Ansible and AWX. Creates Docker
#compose file based on user input. Creates NGINX reverse proxy
#with letsencrypt for ssl.
#

#Disclaimer
DISCLAIMER='###Please ensure that you are runnoing this script locally and that you have configured DNS for you domain prior to continuing.###'
echo $DISCLAIMER
function pause(){
   read -p "$*"
}
pause 'Press [Enter] to continue...'

#User input
echo what is the FQDN
read FQDN
HOST=${FQDN%%.*} 
DOMAIN=${FQDN#*.} 

#Prepare to install stuff
apt update -y
apt install -y apt-transport-https ca-certificates curl software-properties-common 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
apt-add-repository --yes "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt-add-repository --yes ppa:ansible/ansible
add-apt-repository --yes universe
apt update -y
apt upgrade -y

#Install the stuff
apt install -y docker-ce docker-ce-cli
apt install -y python python-simplejson python-pip python-software-properties
apt install -y mosh tmux ufw
apt install -y git wget ansible
pip install docker-py
curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#Do some initial configuring
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 60000:61000/udp
systemctl enable ufw
systemctl start ufw

#Get AWX stuffs
