#!/bin/bash

echo "This script requires root privileges, you will be asked your sudo password"


# Setup PuppetLabs repository
DISTRO=$(grep DISTRIB_CODENAME /etc/lsb-release | awk -F= '{print $2}')
wget -q https://apt.puppetlabs.com/puppetlabs-release-$DISTRO.deb
sudo dpkg -i puppetlabs-release-$DISTRO.deb
sudo apt-get update -y -q

# Install puppet without the agent init script
sudo apt-get install git puppet-common hiera -y -q

# Download uboxen code
cd /opt
[ ! -d /opt/ubuntu-boxen ] && sudo git clone https://github.com/lorello/ubuntu-boxen.git
sudo puppet resource file /usr/local/bin/uboxen ensure=link target=/opt/ubuntu-boxen/uboxen
sudo puppet resource file /etc/puppet/manifests/site.pp ensure=link target=/opt/ubuntu-boxen/uboxen.pp

# Finish
echo -e "\n\nInstallation ended successfully (I hope).\n\nEnjoy Ubuntu Boxen running 'uboxen' at your shell prompt"


