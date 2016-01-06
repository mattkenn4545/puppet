class puppet::master (
  $dns_alt_names            =  'puppet',
  $passenger_max_pool_size  = 12,
  $environment_timeout      = '0'
) inherits puppet {
  package { 'deep_merge':
    provider    => 'gem',
    ensure      => 'installed'
  }

  apt::source { 'passenger':
    location    => 'https://oss-binaries.phusionpassenger.com/apt/passenger',
    repos       => 'main',
    key         => '561F9B9CAC40B2F7',
    key_server  => 'keyserver.ubuntu.com',
  }

  apt::pin { 'puppetmaster':
    ensure      => 'present',
    packages    => 'puppetmaster-common',
    version     => $version,
    priority    => 1001,
    require     => Exec [ 'apt_update' ]
  }

  file { '/etc/puppet/environments':
    ensure      => directory,
    mode        => '0755',
    owner       => 'www-data',
    group       => 'www-data',
    require     => Package [ 'puppet' ]
  }

  package { [ 'nginx-extras', 'passenger', 'puppetmaster-common' ]:
    ensure      => 'installed',
    require     => Exec [ 'apt_update' ]
  } ->
  file { '/var/www':
    ensure      => 'directory'
  } ->
  file { '/var/www/puppetmaster':
    ensure      => 'directory'
  } ->
  file { [ '/var/www/puppetmaster/public', '/var/www/puppetmaster/tmp' ]:
    ensure      => 'directory'
  } ->
  file { '/var/www/puppetmaster/config.ru':
    ensure      => 'present',
    source      => "puppet:///modules/${module_name}/config.ru"
  } ->
  file { '/etc/nginx/sites-available/default':
    ensure      => 'present',
    content     => template("${module_name}/puppetmaster.erb"),
    notify      => Service[ 'nginx' ]
  }

  $config = {
#    'master/ssl_client_header'            =>  { 'value' => 'SSL_CLIENT_S_DN' },
#    'master/ssl_client_verify_header'     =>  { 'value' => 'SSL_CLIENT_VERIFY' },

    'master/always_cache_features'        =>  { 'value' => 'true' },
    'master/environment_timeout'          =>  { 'value' => $environment_timeout },
    'master/environmentpath'              =>  { 'value' => '$confdir/environments' },
    'master/reports'                      =>  { 'value' => 'store, puppetdb' }
  }

  create_resources('puppet_config', $config, { 'tag' => 'master' })

  puppet_config { 'main/dns_alt_names':   value => $dns_alt_names,  tag   => 'master' }

  Puppet_config <| tag == 'master' |> {
    notify      => Service[ 'nginx' ]
  }

  # Cleanup old apache configs
  file { '/etc/apache2/sites-enabled/puppetmaster.conf':
    ensure      => 'absent'
  }
  package { 'apache2':
    ensure      => 'absent'
  }

  cron { 'reports cleanup':
    command     => 'find /var/lib/puppet/reports/* -mtime +7 -type f -exec rm -rf {} \;',
    user        => 'root',
    hour        => 3,
    minute      => 30
  }
}
