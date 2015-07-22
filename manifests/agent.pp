class puppet::agent (
  $runinterval    = '30m',
  $configtimeout  = '600'
) inherits puppet  {
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
    ensure            => 'latest',
    install_options   => '--force-yes'
  } ->

  package { 'cfacter':
    ensure            => 'installed'
  } ->

  file { '/etc/default/puppet':
    ensure    => 'present',
    content   => 'START=true'
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
    'main/environment'              =>  { 'value' => $env },
    'main/server'                   =>  { 'value' => $puppetmaster },
    'main/http_keepalive_timeout'   =>  { 'value' => '25' },

    'agent/runinterval'             =>  { 'value' => $runinterval },
    'agent/always_cache_features'   =>  { 'value' => 'false' },
    'agent/report'                  =>  { 'value' => true },
    'agent/show_diff'               =>  { 'value' => true },
    'agent/usecacheonfailure'       =>  { 'value' => false },
    'agent/configtimeout'           =>  { 'value' => $configtimeout },
    'agent/splay'                   =>  { 'value' => true },
    'agent/pluginsync'              =>  { 'value' => true },
    'agent/cfacter'                 =>  { 'value' => true }
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
    source  => "puppet:///modules/${module_name}/runpuppet"
  }

  file { 'debugpuppet':
    path    => '/bin/debugpuppet',
    owner   => 'root',
    mode    => '0755',
    content => 'sudo puppet agent --verbose --no-daemonize --onetime --no-splay --debug',
  }
}
