
# General DEFAULTS
Package { ensure => latest }

Exec { path => "/usr/bin:/usr/sbin/:/bin:/sbin" }

Vcsrepo {
  provider	=> git,
  require	=> Package['git'],
}

include etckeeper
include apt 

# dnsmasq on a desktop is managed by network manager
# no modules on forge manage this
define dnsmasq::conf($value=''){
  file { "/etc/NetworkManager/dnsmasq.d/${name}":
    content => $value ? { 
      '' 	=> "${name}", 
      default 	=> "${name}=${value}",
    }
  }
}

# General dns conf
dnsmasq::conf { 'no-negcache': }

# Debugging dnsmasq conf
dnsmasq::conf { 'log-queries': }
dnsmasq::conf { 'log-async': value => 25 }

# Dev Environment
dnsmasq::conf { 'address': value => '/dev.it/127.0.1.1' }


# Security
class { 'sudo': 
  require	=> Package['ruby-hiera'],
}

sudo::conf { 'lorello':
  priority => 10,
  content  => 'lorello ALL=(ALL) NOPASSWD: ALL',
}

# Common utilities
package {
  'puppet':;
  'vim-puppet':;
  'ruby-hiera':;

  'vim':;
  'htop':;
  'ipcalc':;
  'hwdata':;
  'network-manager-openvpn':;
  'python-pip':; 
  'p7zip':;
  'git':;
  'aptitude':;
  'curl':;
# Multimedia stuff for RaiSmith project
  'mplayer':;
  'faad':;

}

# Puppet config
file { '/etc/puppet/hiera.yaml':
  content	=> '---',
  require	=> Package['ruby-hiera'],
}


# Git config
# TODO: manage username with hiera
exec { "git config --global user.name \"LoreLLo\"":
  require 	=> Package['git'],
}
exec { "git config --global user.email \"lorenzo.salvadorini@softecspa.it\"":
  require 	=> Package['git'],
}



# PHP development env
package {
  'php5-cli':;
  'php5-json':;
}

$composer_path='/usr/share/php/composer.phar'

file { '/usr/share/php':
  ensure	=> directory,
}

exec { "/usr/bin/curl http://getcomposer.org/composer.phar -o $composer_path":
  creates 	=> $composer_path,
  require 	=> [ File['/usr/share/php'], Package['curl'] ],
}

file { $composer_path:
  mode	=>	'u=rwx,o=rx', 
}

file { '/usr/local/bin/composer':
  ensure	=> link,
  target	=> $composer_path,
}

exec { "$composer_path self-update":
  onlyif 	=> "/usr/bin/test -f $composer_path",
}


# PaaS
package { 'dotcloud': 
  provider 	=> 'pip',
  ensure 	=> 'latest',
}


package { 'skype':
  require => Apt::Source['canonical-partner'],
}

apt::source { 'canonical-partner':
  location  => 'http://archive.canonical.com/ubuntu',
  #release   => $lsbdistcodename,
  repos     => 'partner',
  include_src       => true
}

apt::source { 'google':
  location  => 'http://dl.google.com/linux/chrome/deb/',
  release   => 'stable',
  #repos     => 'main',
  #required_packages => 'debian-keyring debian-archive-keyring',
  key               => '7FAC5991',
  #key_server        => 'subkeys.pgp.net',
  #pin               => '-10',
  include_src       => true
}

apt::source { 'virtualbox':
  location  	=> 'http://download.virtualbox.org/virtualbox/debian',
  release     	=> 'raring',
  repos     	=> 'contrib',
  key           => '7FAC5991',
  include_src   => true,
}

