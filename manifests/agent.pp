class puppet::agent inherits puppet::params {
  apt::pin { 'puppet':
    ensure   => $pin_ensure,
    packages => 'puppet puppet-common',
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
  } -> Puppet_config <| tag == 'agent' |> ~> Service[ 'puppet' ]

  $config = {
    'main/logdir'               =>  { 'value' => '/var/log/puppet' },
    'main/vardir'               =>  { 'value' => '/var/lib/puppet' },
    'main/ssldir'               =>  { 'value' => '/var/lib/puppet/ssl' },
    'main/rundir'               =>  { 'value' => '/var/run/puppet' },
    'main/factpath'             =>  { 'value' => '$vardir/lib/facter' },
    'main/templatedir'          =>  { 'value' => '$confdir/templates' },
    'main/environment'          =>  { 'value' => 'production' },
    'main/server'               =>  { 'value' => $puppetmaster },

    'agent/report'              =>  { 'value' => true },
    'agent/show_diff'           =>  { 'value' => true },
    'agent/usecacheonfailure'   =>  { 'value' => false },
    'agent/configtimeout'       =>  { 'value' => '600' },
    'agent/splay'               =>  { 'value' => true }
  }

  create_resources('puppet_config', $config, { 'tag' => 'agent' })

  Puppet_config <<| title == 'main/ca_server' |>>

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
