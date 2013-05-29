class puppet ( $version = undef ) {

  class { 'puppet::params':
    version => $version,
  }

  package { 'puppetlabs-release':
    ensure => absent,
  }

  apt::source { 'puppetlabs':
    location   => 'http://apt.puppetlabs.com',
    repos      => 'main dependencies',
    key        => '4BD6EC30',
    key_server => 'pgp.mit.edu',
  }

  file { '/etc/puppet/puppet.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => 0644,
    source  => "puppet:///modules/${module_name}/puppet.conf",
    require => Package[ 'puppet' ],
    notify  => Service[ 'puppet' ],
  }
}
