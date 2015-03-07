class puppet::agent inherits puppet {
  apt::pin { 'puppet':
    ensure   => 'present',
    packages => 'puppet puppet-common',
    version  => $version,
    priority => 1001,
  }

  # Needed to make factor work with 14.04
  package { 'update-notifier-common':
    ensure  => 'installed'
  } ~> Service [ 'puppet' ]

  package { 'puppet':
    ensure  => 'latest',
  } ->

  ini_setting { 'enablepuppet':
    ensure  => present,
    path    => '/etc/default/puppet',
    section => '',
    setting => 'START',
    value   => 'yes'
  } ~>

  service { 'puppet':
    enable      => true,
    ensure      => running,
    hasrestart  => true
  }

  $config = {
    'main/logdir'                   =>  { 'value' => '/var/log/puppet' },
    'main/vardir'                   =>  { 'value' => '/var/lib/puppet' },
    'main/ssldir'                   =>  { 'value' => '/var/lib/puppet/ssl' },
    'main/rundir'                   =>  { 'value' => '/var/run/puppet' },
    'main/environment'              =>  { 'value' => 'production' },
    'main/server'                   =>  { 'value' => $puppetmaster },
    'main/http_keepalive_timeout'   =>  { 'value' => '25' },

    'agent/always_cache_features'   =>  { 'value' => 'false' },
    'agent/report'                  =>  { 'value' => true },
    'agent/show_diff'               =>  { 'value' => true },
    'agent/usecacheonfailure'       =>  { 'value' => false },
    'agent/configtimeout'           =>  { 'value' => '600' },
    'agent/splay'                   =>  { 'value' => true },
    'agent/pluginsync'              =>  { 'value' => true }
  }

  create_resources('puppet_config', $config, { 'tag' => 'agent' })

  Puppet_config <<| title == 'main/ca_server' |>>

  Puppet_config <| tag == 'agent' |> {
    notify => Service[ 'puppet' ]
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
