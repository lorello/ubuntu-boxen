#!/bin/bash

echo "This script requires root privileges, you will be asked your sudo password"


# Setup PuppetLabs repository
DISTRO=$(grep DISTRIB_CODENAME /etc/lsb-release | awk -F= '{print $2}')
wget -q https://apt.puppetlabs.com/puppetlabs-release-$DISTRO.deb
sudo dpkg -i puppetlabs-release-$DISTRO.deb
sudo apt-get update -y -q

# Install puppet without the agent init script
sudo apt-get install puppet-common -y -q


