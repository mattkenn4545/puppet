class puppet::agent (
    $version = $puppet::params::version,
) inherits puppet::params {


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
    notify  => Exec['kill-puppet'],
  }

  exec { "kill-puppet":
    command     => "killall -9 puppet",
    refreshonly =>  true,
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
}