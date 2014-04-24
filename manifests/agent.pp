class puppet::agent (
  $node_terminus          = hiera('puppet::agent::node_terminus', 'plain')
) inherits puppet::params {
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
  } ->

  file { '/etc/puppet/puppet.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => 644,
    content => template("${module_name}/puppet.conf.erb"),
    notify  => Service[ 'puppet' ]
  } ->

  ini_setting { 'enablepuppet':
    ensure  => present,
    path    => '/etc/default/puppet',
    section => '',
    setting => 'START',
    value   => 'yes'
  } ->

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
