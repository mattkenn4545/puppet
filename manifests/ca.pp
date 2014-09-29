class puppet::ca (
  $autosign               = hiera('puppet::ca::autosign', '')
) inherits puppet::params {
  include puppet::master

  @@puppet_config { 'main/ca_server': value => $fqdn }

  file { '/etc/puppet/autosign.conf':
    ensure    => present,
    content   => $autosign,
    notify    => Service[ 'apache2' ],
    require   => Package[ 'puppetmaster-passenger' ]
  }
}
