class puppet::master (
  $autosign               = hiera('puppet::master::autosign', '')
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
    ensure    => 'latest',
    before    => Service[ 'puppet' ],
    notify    => Service[ 'apache2' ]
  } ->

  file { '/etc/puppet/auth.conf':
    mode      => '0644',
    owner     => 'root',
    group     => 'root',
    source    => "puppet:///modules/${module_name}/auth.conf",
    notify    => Service[ 'apache2' ]
  } ->

  file { '/etc/puppet/autosign.conf':
    ensure    => present,
    content   => $autosign,
    notify    => Service[ 'apache2' ]
  } ->

  file { '/etc/puppet/environments':
    ensure    => directory,
    mode      => '0755',
    owner     => $environment_dir_owner,
    group     => $environment_dir_owner
  }

  ini_setting { 'puppet.conf/master/manifest':
    ensure  => present,
    section => 'master',
    path    => '/etc/puppet/puppet.conf',
    setting => 'manifest',
    value   => '$confdir/environments/$environment/manifests/site.pp',
    notify  => Service[ 'apache2' ]
  }

  ini_setting { 'puppet.conf/master/modulepath':
    ensure  => present,
    section => 'master',
    path    => '/etc/puppet/puppet.conf',
    setting => 'modulepath',
    value   => '$confdir/environments/$environment/modules',
    notify  => Service[ 'apache2' ]
  }

  ini_setting { 'puppet.conf/master/reports':
    ensure  => present,
    section => 'master',
    path    => '/etc/puppet/puppet.conf',
    setting => 'reports',
    value   => 'store, http',
    notify  => Service[ 'apache2' ]
  }

  #TODO This should be exported from the puppetdashboard node
  ini_setting { 'puppet.conf/master/reporturl':
    ensure  => present,
    section => 'master',
    path    => '/etc/puppet/puppet.conf',
    setting => 'reporturl',
    value   => "http://${puppetmaster}:3000/reports/upload",
    notify  => Service[ 'apache2' ]
  }

  cron { 'reports cleanup':
    command   => 'find /var/lib/puppet/reports/* -mtime +7 -type f -exec rm -rf {} \;',
    user      => root,
    hour      => 3,
    minute    => 30
  }
}
