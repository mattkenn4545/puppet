class puppet::master (
  $dns_alt_names            =  "puppet",
  $passenger_max_pool_size  = 12
) inherits puppet {
  if (defined(Class[ 'puppet::master_git'])){
    $environment_dir_owner  = 'git'
  } else {
    $environment_dir_owner  = 'www-data'
  }

  package { 'deep_merge':
    provider  => 'gem',
    ensure    => 'installed'
  }

  apt::pin { 'puppetmaster':
    ensure    => 'present',
    packages  => 'puppetmaster-common puppetmaster-passenger',
    version   => $version,
    priority  => 1001
  }

  package { 'puppetmaster-passenger':
    ensure    => 'installed',
    before    => Service[ 'puppet' ],
    notify    => Service[ 'apache2' ]
  } ->

  file { '/etc/puppet/environments':
    ensure    => directory,
    mode      => '0755',
    owner     => $environment_dir_owner,
    group     => $environment_dir_owner
  }

  file { '/etc/apache2/sites-available/puppetmaster.conf':
    ensure    => 'present',
    content   => template("${module_name}/puppetmaster.conf.erb"),
    notify    => Service[ 'apache2' ]
  }

  $config = {
    'master/ssl_client_header'            =>  { 'value' => 'SSL_CLIENT_S_DN' },
    'master/ssl_client_verify_header'     =>  { 'value' => 'SSL_CLIENT_VERIFY' },

    'master/always_cache_features'        =>  { 'value' => 'true' },
    'master/environment_timeout'          =>  { 'value' => '0' },
    'master/filetimeout'                  =>  { 'value' => '60s' },
    'master/environmentpath'              =>  { 'value' => '$confdir/environments' },
    'master/reports'                      =>  { 'value' => 'store, puppetdb' }
  }

  create_resources('puppet_config', $config, { 'tag' => 'master' })

  puppet_config { 'main/dns_alt_names':   value => $dns_alt_names,  tag   => 'master' }

  Puppet_config <| tag == 'master' |> {
    notify => Service[ 'apache2' ]
  }

  cron { 'reports cleanup':
    command   => 'find /var/lib/puppet/reports/* -mtime +7 -type f -exec rm -rf {} \;',
    user      => root,
    hour      => 3,
    minute    => 30
  }
}
