class puppet::agent inherits puppet::params {
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
    ensure  => 'latest',
  } ->

  ini_setting { 'enablepuppet':
    ensure  => present,
    path    => '/etc/default/puppet',
    section => '',
    setting => 'START',
    value   => 'yes',
    notify  => Service[ 'puppet' ]
  }

#  puppet_config { 'test/setting':
#    value => 'works'
#  }

  ini_setting { 'puppet.conf/main/environment':
    ensure  => present,
    section => 'main',
    path    => '/etc/puppet/puppet.conf',
    setting => 'environment',
    value   => 'production',
    notify  => Service[ 'puppet' ]
  }

  ini_setting { 'puppet.conf/main/server':
    ensure  => present,
    section => 'main',
    path    => '/etc/puppet/puppet.conf',
    setting => 'server',
    value   => $puppetmaster,
    notify  => Service[ 'puppet' ]
  }

  ini_setting { 'puppet.conf/agent/report':
    ensure  => present,
    section => 'agent',
    path    => '/etc/puppet/puppet.conf',
    setting => 'report',
    value   => true,
    notify  => Service[ 'puppet' ]
  }

  ini_setting { 'puppet.conf/agent/show_diff':
    ensure  => present,
    section => 'agent',
    path    => '/etc/puppet/puppet.conf',
    setting => 'show_diff',
    value   => true,
    notify  => Service[ 'puppet' ]
  }

  ini_setting { 'puppet.conf/agent/usecacheonfailure':
    ensure  => present,
    section => 'agent',
    path    => '/etc/puppet/puppet.conf',
    setting => 'usecacheonfailure',
    value   => false,
    notify  => Service[ 'puppet' ]
  }

  ini_setting { 'puppet.conf/agent/configtimeout':
    ensure  => present,
    section => 'agent',
    path    => '/etc/puppet/puppet.conf',
    setting => 'configtimeout',
    value   => '600',
    notify  => Service[ 'puppet' ]
  }

  ini_setting { 'puppet.conf/agent/splay':
    ensure  => present,
    section => 'agent',
    path    => '/etc/puppet/puppet.conf',
    setting => 'splay',
    value   => true,
    notify  => Service[ 'puppet' ]
  }

  service { 'puppet':
    enable      => true,
    ensure      => running,
    hasrestart  => true
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
