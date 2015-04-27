# Setup of uboxen

file { 
  '/usr/local/bin/uboxen':
    ensure => link,
    target => '/opt/ubuntu-boxen/uboxen';
  '/etc/puppet/manifests/site.pp':
    ensure => link,
    target => '/opt/ubuntu-boxen/uboxen.pp';
  '/etc/puppet/modules':
    ensure => link,
    target => '/opt/ubuntu-boxen/modules';
  '/var/lib/hiera':
    ensure => link,
    target => '/opt/ubuntu-boxen/data';
}
