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
    ensure            => 'installed',
    notify            => Service[ 'puppet' ]
  }

  package { 'puppet':
    ensure            => 'latest',
    install_options   => '--force-yes',
    notify            => Service[ 'puppet' ],
    require           => Exec [ 'apt_update' ]
  } ->

  package { 'cfacter':
    ensure            => 'latest',
    notify            => Service[ 'puppet' ],
    require           => Exec [ 'apt_update' ]
  } ->

  file { '/etc/default/puppet':
    ensure            => 'present',
    content           => 'START=true',
    notify            => Service[ 'puppet' ]
  }

  service { 'puppet':
    enable      => true,
    ensure      => running,
    hasrestart  => true
  }

  $config = {
    'main/logdir'                             =>  { 'value' => '/var/log/puppet' },
    'main/vardir'                             =>  { 'value' => '/var/lib/puppet' },
    'main/ssldir'                             =>  { 'value' => '/var/lib/puppet/ssl' },
    'main/rundir'                             =>  { 'value' => '/var/run/puppet' },
    'main/environment'                        =>  { 'value' => $env },
    'main/server'                             =>  { 'value' => $puppetmaster },
    'main/http_keepalive_timeout'             =>  { 'value' => '25' },
#    'main/preferred_serialization_format'     =>  { 'value' => 'msgpack' },

    'agent/runinterval'                       =>  { 'value' => $runinterval },
    'agent/always_cache_features'             =>  { 'value' => false },
    'agent/ignorecache'                       =>  { 'value' => true },
    'agent/usecacheonfailure'                 =>  { 'value' => false },
    'agent/report'                            =>  { 'value' => true },
    'agent/show_diff'                         =>  { 'value' => true },
    'agent/configtimeout'                     =>  { 'value' => $configtimeout },
    'agent/splay'                             =>  { 'value' => true },
    'agent/pluginsync'                        =>  { 'value' => true },
    'agent/cfacter'                           =>  { 'value' => true },
    'agent/catalog_cache_terminus'            =>  { 'value' => '' }
  }

  package { 'msgpack':
    provider    => 'gem',
    ensure      => 'absent',
    notify      => Service[ 'puppet' ]
  }

  tidy { '/var/lib/puppet/client_data':
    age       => 0,
    recurse   => true,
    backup    => false
  }

  tidy { '/var/lib/puppet/clientbucket':
    age       => '2w',
    recurse   => true,
    rmdirs    => true,
    backup    => false
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
