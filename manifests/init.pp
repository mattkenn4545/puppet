class puppet (
  $version = undef,
  $puppetmaster = 'puppet'
) {

  class { 'puppet::params':
    version       => $version,
    puppetmaster  => $puppetmaster,
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
    content => template("${module_name}/puppet.conf.erb"),
    require => Package[ 'puppet' ],
    notify  => Service[ 'puppet' ],
  }

  Exec["apt_update"] -> Package <| |>
}
