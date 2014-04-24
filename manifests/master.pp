class puppet::master (
  $autosign               = hiera('puppet::master::autosign', ''),
  $node_terminus          = hiera('puppet::master::node_terminus', 'plain')
) inherits puppet::params {
  if (defined(Class[ 'puppet::master_git'])){
    $environment_dir_owner  = 'git'
  } else {
    $environment_dir_owner  = 'www-data'
  }

  host { 'puppet':
    ensure    => present,
    ip        => '127.0.1.1',
    before    => Service[ 'puppet' ]
  }

  apt::pin { 'puppetmaster-passenger':
    ensure    => $pin_ensure,
    packages  => 'puppetmaster-passenger',
    version   => $version,
    priority  => 1001
  }

  apt::pin { 'puppetmaster-common':
    ensure    => $pin_ensure,
    packages  => 'puppetmaster-common',
    version   => $version,
    priority  => 1001
  }

  package { 'puppetmaster-passenger':
    ensure    => latest,
    before    => Service[ 'puppet' ]
  } ->

  file { '/etc/puppet/auth.conf':
    mode      => '0644',
    owner     => 'root',
    group     => 'root',
    source    => "puppet:///modules/${module_name}/auth.conf"
  } ->

  file { '/etc/puppet/autosign.conf':
    ensure    => present,
    content   => $autosign
  } ->

  file { '/etc/puppet/environments':
    ensure    => directory,
    mode      => '0755',
    owner     => $environment_dir_owner,
    group     => $environment_dir_owner
  }

  cron { 'reports cleanup':
    command   => 'find /var/lib/puppet/reports/* -mtime +7 -type f -exec rm -rf {} \;',
    user      => root,
    hour      => 3,
    minute    => 30
  }
}
