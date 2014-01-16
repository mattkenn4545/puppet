class puppet::agent inherits puppet::params {
  if $version == undef { $pin_ensure = 'absent' }
  else {  $pin_ensure = 'present' }

  apt::pin { 'puppet':
    ensure   => $pin_ensure,
    packages => 'puppet',
    version  => $version,
    priority => 1001,
  }

  apt::pin { 'puppet-common':
    ensure   => $pin_ensure,
    packages => 'puppet-common',
    version  => $version,
    priority => 1001,
  }

  package { 'puppet':
    ensure  => latest,
  }

  ini_setting { 'enablepuppet':
    ensure  => present,
    path    => '/etc/default/puppet',
    section => '',
    setting => 'START',
    value   => 'yes',
    require => Package[ 'puppet' ],
  }

  service { 'puppet':
    enable      => true,
    ensure      => running,
    hasrestart  => true,
    require     => [ Package[ 'puppet' ], Ini_setting[ 'enablepuppet' ] ],
  }

  file { 'runpuppet':
    path    => '/bin/runpuppet',
    owner   => 'root',
    mode    => '0755',
    content => 'sudo puppet agent --verbose --no-daemonize --onetime --no-splay',
  }

  file { 'debugpuppet':
    path    => '/bin/debugpuppet',
    owner   => 'root',
    mode    => '0755',
    content => 'sudo puppet agent --verbose --no-daemonize --onetime --no-splay --debug',
  }
}
