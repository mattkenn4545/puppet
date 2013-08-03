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

  package { 'rubygems':
    ensure => present,
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

  cron { 'reports cleanup':
    command => 'find /var/lib/puppet/reports/* -mtime +1 -type f -exec rm -rf {} \;',
    user    => root,
    hour    => 3,
    minute  => 30
  }

  if $::fqdn == 'puppet.vnet' {
    file { '/etc/puppet/environments/production':
      ensure  => link,
      target  => '/vagrant',
      require => File['/etc/puppet/environments'],
    }

    file { '/etc/puppet/autosign.conf':
      ensure  => present,
      content  => '*',
      require => File['/etc/puppet/environments'],
    }
  }
}
