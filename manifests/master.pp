class puppet::master (
  $dns_alt_names    =  "puppet,puppet.${domain}"
) inherits puppet {
  if (defined(Class[ 'puppet::master_git'])){
    $environment_dir_owner  = 'git'
  } else {
    $environment_dir_owner  = 'www-data'
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

  $config = {
#    'master/always_cache_features'        =>  { 'value' => 'true' }, # TODO We prob want this turned on
    'master/environment_timeout'          =>  { 'value' => '2s' },
    'master/filetimeout'                  =>  { 'value' => '2s' },
    'master/ignorecache'                  =>  { 'value' => 'true' },  # Turn this to false when live
    'master/environmentpath'              =>  { 'value' => '$confdir/environments' },
    'master/reports'                      =>  { 'value' => 'store, http' } # Will have the http bit removed soon
  }

  create_resources('puppet_config', $config, { 'tag' => 'master' })

  puppet_config { 'main/dns_alt_names':   value => $dns_alt_names,  tag   => 'master' }

  Puppet_config <<| title == 'master/reporturl' |>>

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
