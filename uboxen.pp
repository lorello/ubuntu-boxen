class puppetdevtools {
  # Puppet dev environment
  package { [ 'libxslt-dev', 'libxml2-dev']: ensure => present }
  package { 'nokogiri':
    ensure => '1.5.11',
    provider => 'gem',
    require => [ Package['libxslt-dev'], Package['libxml2-dev']],
  }
  package { [ 'ruby-dev', 'ruby-hiera' ] : ensure => present }
  package { [ 'puppet-lint', 'puppet-syntax', 'librarian-puppet', 'rspec-puppet', 'puppetlabs_spec_helper', 'r10k' ]:
    provider => 'gem',
    ensure   => 'present',
  }
  vim::plugin { 'puppet':
    source => 'https://github.com/rodjek/vim-puppet.git',
    require => [ Vim::Plugin['tabular'], Vim::Plugin['snippets'] ],
  }

}

define motd::usernote($content = '') {
  file { "/etc/update-motd.d/60-${name}":
    content  => $content,
  }
}

define git::config(
  $section='',
  $key='',
  $value,
  $user='')
{

  include git

  if empty($user)
  {
    $real_command = "git config --system"
  } else {
    validate_string($user)
    $real_command = "sudo -u ${user} git config --global"
  }

  if empty($section) and empty($key) {
    validate_re($name, '^\w+\.\w+$')
    $real_section_key = $name
  } else {
    $real_section_key = "${section}.${key}"
  }

  exec { $real_section_key:
    command => "${real_command} ${real_section_key} \"$value\"",
    unless  => "test \"`${real_command} ${real_section_key}`\" = \"${value}\"",
    require => Package['git'],
  }
}

class bash {

  package { [ 'bash', 'bash-completion', 'command-not-found' ] :
    ensure => latest,
  }

  file { '/etc/profile.d/load-puppet-profile.sh':
    content => "# file generated by puppet\n[ -f ~/.bashrc.puppet ] && source ~/.bashrc.puppet\n",
  }

}


# if user specified add config to ~/.bashrc.puppet
# else add config to system-wide bashrc.puppet.sh
define bash::rc(
  $content = '',
  $user = undef,
) {
  validate_string($content)

  $real_content = $content ? {
    ''      => $name,
    default => "# $name\n$content",
  }

  if $user {
    validate_string($user)
    $real_target = "/home/$user/.bashrc.puppet"
    validate_absolute_path($real_target)
  } else {
    $real_target  = '/etc/profile.d/bashrc.puppet.sh'
  }

  if ! defined(Concat[$real_target]) {
    concat { $real_target : }
    concat::fragment { 'systemwide-bashrc-header':
      content => "# file generated by Puppet\n\n",
      target  => $real_target,
      order   => '00',
    }
  }

  concat::fragment { $name:
    target  => $real_target,
    content => "$real_content\n\n",
  }
}


class profile::phpredis {
  # Redis server
  class { 'redis': }
  # required for php-redis package
  apt::ppa { 'ppa:ufirst/php' :
    require => File['/etc/php5/conf.d'],
  }

  # required for php-redis package
  file { '/etc/php5/conf.d':
    ensure => directory,
  }

  file { '/etc/php5/mods-available/redis.ini':
    target => '/etc/php5/conf.d/redis.ini',
    require => Package['php5-redis'],
  }

  file { '/etc/php5/cli/conf.d/20-redis.ini':
    target => '../../mods-available/redis.ini',
  }

  Package['php5-redis'] -> Apt::Ppa['ppa:ufirst/php']

}

# PHP development env
class profile::phpdev {

  include php
  Package['php5-dev'] -> Php::Extension <| |> -> Php::Config <| |>

  class {
    'php::cli':;
    'php::dev':;
    'php::pear':;
    'php::extension::curl':;
    'php::extension::redis':;
    'php::composer':;
    'php::phpunit':;
  }
  package {'php5-json':; }

  class { 'composer':
    require => Package ['php5-curl'],
  }
}

node generic_host {

  bash::rc { 'alias ll="ls -lv --group-directories-first"': }
  bash::rc { 'alias rm="rm -i"': }
  bash::rc { 'alias mv="mv -i"': }
  bash::rc { 'alias mkdir="mkdir -p"': }
  bash::rc { 'alias df="df -kTh"': }
  bash::rc { 'alias ..="cd .."': }
  bash::rc { 'alias svim="sudo vim"': }
  bash::rc { 'Sort by date, most recent last': content => 'alias lt="ls -ltr"' }
  bash::rc { 'Sort by size, biggest last': content => 'alias lk="ls -lSr"' }
  bash::rc { 'alias grep="grep --color=always"': }

  bash::rc { 'alias update="sudo apt-get update"': }
  bash::rc { 'alias upgrade="update && sudo apt-get upgrade"': }
  bash::rc { 'alias install="sudo apt-get install"': }

  bash::rc { 'alias netscan="nmap -A -sP"': }
  bash::rc { 'alias netscan0="nmap -A -PN"': }
  bash::rc { 'alias hostscan="nmap -A -T4"': }

  bash::rc { 'alias goodpass="pwgen -scnvB -C 16 -N 1"': }
  bash::rc { 'alias goodpass8="pwgen -scnvB -C 8 -N 1"': }
  bash::rc { 'alias strongpass="pwgen -scynvB -C 16 -N 1"': }
  bash::rc { 'alias strongpass8="pwgen -scynvB -C 8 -N 1"': }

  bash::rc { 'Command-line calculator':
    content => "calc (){\n\techo \"\$*\" | bc -l;\n}",
  }

  bash::rc { 'sniff url':
    content => 'alias sniff="sudo ngrep -tipd any -Wbyline \'/api/v1/verb\' tcp port 80"',
    require => Package['ngrep'],
  }

  git::config { 'alias.up' :              value => 'pull origin' }
  git::config { 'core.sharedRepository':  value => 'group' }
  git::config { 'color.interactive':      value => 'auto' }
  git::config { 'color.showbranch':       value => 'auto' }
  git::config { 'color.status' :          value => 'auto' }


}

node generic_desktop {

 # General dns conf
  dnsmasq::conf { 'general-options':
    content => "no-negcache\nlog-queries\nlog-async=50\n",
  }

  # Dev Environment
  dnsmasq::conf { 'resolv-dev.it':
    content   => 'address=/dev.it/127.0.1.1',
  }
  motd::usernote { 'dnsmasq':
    content => "Domains *.dev.it points to localhost, use it for your dev environments",
  }

  # Security
  class { 'sudo':
    require	=> Package['ruby-hiera'],
  }
  sudo::conf { 'wheel-group':
    priority => 10,
    content  => "%wheel ALL=(ALL) NOPASSWD: ALL",
  }
  group { 'wheel':
    ensure => 'present',
  }

  include docker
  include vagrant

  package { 'skype':
    require => Apt::Source['canonical-partner'],
  }

  apt::source { 'canonical-partner':
    location    => 'http://archive.canonical.com/ubuntu',
    repos       => 'partner',
    include_src => true
  }

  # Google
  apt::source { 'google-chrome':
    location  	=> 'http://dl.google.com/linux/chrome/deb/',
    release   	=> 'stable',
    key         => '7FAC5991',
    include_src => false,
  }
  apt::source { 'google-talkplugin':
    location  	=> 'http://dl.google.com/linux/talkplugin/deb/',
    release   	=> 'stable',
    key           => '7FAC5991',
    include_src   => false,
  }


  package { 'dkms': 		      ensure	=> latest }

  package { 'gedit':          ensure => latest }
  wget::fetch { 'gedit-solarized-theme-dark':
    source      => 'https://raw.github.com/altercation/solarized/master/gedit/solarized-dark.xml',
    destination => '/usr/share/gtksourceview-3.0/styles/solarized-dark.xml',
    require     => Package['gedit'],
  }
  wget::fetch { 'gedit-solarized-theme-light':
    source      => 'https://raw.github.com/altercation/solarized/master/gedit/solarized-light.xml',
    destination => '/usr/share/gtksourceview-3.0/styles/solarized-light.xml',
    require     => Package['gedit'],
  }

}


class vagrant {

  package { 'virtualbox': ensure	=> latest }
  package { 'vagrant': 		    ensure	=> latest }
  wget::fetch { 'vagrant-bash-completion':
    source      => 'https://github.com/kura/vagrant-bash-completion/raw/master/vagrant',
    destination => '/etc/bash_completion.d/vagrant',
  }

  bash::rc { 'alias vu="vagrant up"' : }
  bash::rc { 'alias vp="vagrant provision"' : }
  bash::rc { 'alias vs="vagrant suspend"' : }

  dnsmasq::conf { 'resolve-vagrant.local':
    content  => 'address=/vagrant.local/127.0.1.1',
  }
}

class consul {
  dnsmasq::conf { 'resolve-consul':
    content => 'server=/consul/127.0.0.1#8600',
  }
}


define vagrant::box(
  $source,
  $username = 'root',
){

  include vagrant

  $home = $username ? {
    'root'  => '/root',
    default => "/home/${username}"
  }

  if ! defined(File['vagrant-home']) {
    file { 'vagrant-home':
      path   => "${home}/vagrant",
      owner  => $username,
      ensure => directory,
    }
  }

  vcsrepo { "${home}/vagrant/${name}":
    source   => $source,
    ensure   => present,
    provider => git,
    require  => Package['git'],
  }

  file { "${home}/vagrant/${name}":
    owner   => $username,
    recurse => true,
  }
}


class ubuntu::nautilus {
  package { 'nautilus-compare': ensure => latest }
}

class desktop::proxy(
  $proxy,
  $noproxy = '127.0.0.1,127.0.1.1,localhost,*.local',
){
  package{ 'polipo': ensure => latest }
  bash::rc { 'setup polipo as a system wide proxy':
    content => "export {http,https,ftp}_proxy='http://${proxy}'",
  }
  if $noproxy {
    bash::rc { 'proxy skip rules':
      content => "export https_no_proxy='${noproxy}'\nexport http_no_proxy='${noproxy}'"
    }
  }
}

class profile::mongo 
{
  # mongodb
  class {'::mongodb::globals':
      manage_package_repo => true,
  }->
  class {'::mongodb::server': }

  # mongo single page app manager
  package { 'genghisapp':
    provider => gem,
  }
  package { 'mongo':
    ensure   => installed,
    provider => pecl;
  }


}

node motokosony {

  file { "$unix_home/.xprofile" :
    content => "SYSRESOURCES=/etc/X11/Xresources\nUSRRESOURCES=\$HOME/.Xresources\n",
    owner    => $unix_user,
  }

  git::config { 'user.name' : user => $unix_user, value => $unix_user }
  git::config { 'user.email': user => $unix_user, value => $email }

  class { 'vim':
    user	=> $unix_user,
    home_dir => $unix_home,
  }

  # Vim colorscheme - http://ethanschoonover.com/solarized
  vim::plugin { 'colors-solarized':
    source => 'https://github.com/altercation/vim-colors-solarized.git',
  }
  vim::plugin { 'colors-monokai':
    source => 'https://github.com/sickill/vim-monokai.git',
  }
  vim::plugin { 'colors-gruvbox':
    source => 'https://github.com/morhetz/gruvbox.git',
  }
  vim::rc { 'sane-text-files':
    content => "set fileformat=unix\nset encoding=utf-8",
  }
  vim::rc { 'set number': }
  vim::rc { 'set tabstop=2': }
  vim::rc { 'set shiftwidth=2': }
  vim::rc { 'set softtabstop=2': }
  vim::rc { 'set expandtab': }

  vim::rc { 'set pastetoggle=<F6>': }

  vim::rc { 'intuitive-split-positions':
    content => "set splitbelow\nset splitright",
  }

  vim::rc { 'silent! colorscheme solarized': }
  #vim::rc { 'silent! colorscheme monokai': }
  vim::rc { 'background-x-gui':
    content => "if has('gui_running')\n\tset background=light\nelse\n\tset background=dark\nendif",
  }
  # Vim plugin: syntastic
  vim::plugin { 'syntastic':
    source => 'https://github.com/scrooloose/syntastic.git',
  }
  vim::plugin { 'tabular':
    source => 'https://github.com/godlygeek/tabular.git',
  }
  vim::plugin { 'snippets':
    source => 'https://github.com/honza/vim-snippets.git',
  }
  vim::plugin { 'enhanced-status-line':
    source => 'https://github.com/millermedeiros/vim-statline.git',
  }

  vim::plugin { 'nerdtree-and-tabs-together':
    source => 'https://github.com/jistr/vim-nerdtree-tabs.git',
  }
  vim::rc { 'nerdtree-start-on-console':
    content => 'let g:nerdtree_tabs_open_on_console_startup=1',
  }

  vim::plugin { 'tasklist':
    source => 'https://github.com/superjudge/tasklist-pathogen.git',
  }

  #vim::plugin { 'rainbow-parenthesis':
  #  source => 'https://github.com/oblitum/rainbow.git',
  #}
  vim::rc { 'activate rainbow parenthesis globally':
    content => 'let g:rainbow_active = 1',
  }

  vagrant::box { 'hhvm':
    source   => 'https://github.com/javer/hhvm-vagrant-vm',
    username => $unix_user,
  }

  # picasa
  package { [ 'wine', 'winetricks']:  ensure => latest }


  class { 'desktop::proxy':
    proxy => '127.0.0.1:8123',
  }
}

class profile::git(
  $config,
) {
  create_resources('git::config', $config)
}

class profile::bash(
  $rc,
) {
  create_resources('bash::rc', $rc)
}

class profile::software(
  $packages,
  $ppas,
){

  validate_array($packages)
  validate_hash($ppas)

  $defaults = {
    ensure => latest
  }

  if $packages {
    package { $packages: ensure => latest }
  }
  if $ppas {
    create_resources('profile::software::ppa', $ppas, $defaults)
  }

}

define profile::software::ppa(
  $ensure  = latest,
  $packages = [],
)
{
    apt::ppa { "ppa:${name}": }

    validate_array($packages)

    if $packages {
        package { $packages:
            ensure => $ensure
        }
    }
}

class profile::owner(
  $username,
  $email,
  $groups,
) {
  user { $username:
    ensure => present,
  }

  sudo::conf { $username:
    priority => 10,
    content  => "${username} ALL=(ALL) NOPASSWD: ALL",
  }

  user { $username :
    groups => $groups,
  }

}

node default {
}

# General DEFAULTS
#Exec { path => '/usr/bin:/usr/sbin/:/bin:/sbin' }

hiera_include('classes', [ 'stdlib' ])

