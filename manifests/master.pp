class puppet::master (
) inherits puppet::params {
  if (defined(Class[ 'puppet::master_git'])){
    $environment_dir_owner  = 'git'
  } else {
    $environment_dir_owner  = 'www-data'
  }

  apt::pin { 'puppetmaster':
    ensure    => $pin_ensure,
    packages  => 'puppetmaster-common puppetmaster-passenger',
    version   => $version,
    priority  => 1001
  }

  package { 'puppetmaster-passenger':
    ensure    => 'installed',
    before    => Service[ 'puppet' ],
    notify    => Service[ 'apache2' ]
  } ->

  file { '/etc/puppet/auth.conf':
    mode      => '0644',
    owner     => 'root',
    group     => 'root',
    source    => "puppet:///modules/${module_name}/auth.conf",
    notify    => Service[ 'apache2' ]
  } ->

  file { '/etc/puppet/environments':
    ensure    => directory,
    mode      => '0755',
    owner     => $environment_dir_owner,
    group     => $environment_dir_owner
  } -> Puppet_config <| tag == 'master' |> ~> Service[ 'apache2' ]

  $config = {
    'master/ssl_client_header'            =>  { 'value' => 'SSL_CLIENT_S_DN' },
    'master/ssl_client_verify_header'     =>  { 'value' => 'SSL_CLIENT_VERIFY' },
    'master/manifest'                     =>  { 'value' => '$confdir/environments/$environment/manifests/site.pp' },
    'master/modulepath'                   =>  { 'value' => '$confdir/environments/$environment/modules' },
    'master/reports'                      =>  { 'value' => 'store, http' },
    'master/reporturl'                    =>  { 'value' => "http://${puppetmaster}:3000/reports/upload" }
  }

  create_resources('puppet_config', $config, { 'tag' => 'master' })

  puppet_config { 'main/dns_alt_names':
    value => "puppet,puppet.${domain}"
  }

  cron { 'reports cleanup':
    command   => 'find /var/lib/puppet/reports/* -mtime +7 -type f -exec rm -rf {} \;',
    user      => root,
    hour      => 3,
    minute    => 30
  }
}
