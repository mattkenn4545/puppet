class puppet::master (
    $version = $puppet::params::version,
    $environment_dir_owner = 'www-data',
) inherits puppet::params {


  if $version == undef { $pin_ensure = 'absent' }
  else {  $pin_ensure = 'present' }

  apt::pin { 'puppetmaster-passenger':
    ensure   => $pin_ensure,
    packages => 'puppetmaster-passenger',
    version  => $version,
    priority => 1001,
  }

  apt::pin { 'puppetmaster-common':
    ensure   => $pin_ensure,
    packages => 'puppetmaster-common',
    version  => $version,
    priority => 1001,
  }

  package { 'puppetmaster-passenger':
    ensure  => latest,
    before  => Service[ 'puppet' ],
  }

  host { 'puppet':
    ensure  => present,
    ip      => '127.0.1.1',
    before  => Service[ 'puppet' ],
  }

  file { '/etc/puppet/auth.conf':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    source  => "puppet:///modules/${module_name}/auth.conf",
    require => Package[ 'puppetmaster-passenger' ],
  }

  file { '/etc/puppet/environments':
    ensure => directory,
    mode    => '0755',
    owner   => $environment_dir_owner,
    group   => $environment_dir_owner,
    require => Package[ 'puppetmaster-passenger' ],
  }
}
