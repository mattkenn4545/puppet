class puppet {
  package { 'puppetlabs-release':
    ensure => absent,
  }

  file { '/etc/apt/apt.conf':
    content => '',
    before  => Apt::Source['puppetlabs'],
  }

  apt::source { 'puppetlabs':
    location   => 'http://apt.puppetlabs.com',
    repos      => 'main dependencies',
    key        => '4BD6EC30',
    key_server => 'pgp.mit.edu',
  }

  package { 'puppet':
    ensure  => latest,
    notify  => Exec['kill-puppet'],
  }

  exec { "kill-puppet":
    command     => "killall -9 puppet",
    refreshonly =>  true,
  }

  service { 'puppet':
    enable      => true,
    ensure      => running,
    hasrestart  => true,
    require     => [ Package[ 'puppet' ], Ini_setting[ 'enablepuppet' ] ],
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

  ini_setting { 'enablepuppet':
    ensure  => present,
    path    => '/etc/default/puppet',
    section => '',
    setting => 'START',
    value   => 'yes',
    require => Package[ 'puppet' ],
  }
}
