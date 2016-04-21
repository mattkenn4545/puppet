class puppet (
  $version        = undef,
  $puppetmaster   = 'puppet',
  $purge_config   = true,
  $env            = 'production'
) {
  apt::source { 'puppetlabs':
    location   => 'http://apt.puppetlabs.com',
    repos      => 'main dependencies',
    key        => '47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
    key_server => 'pgp.mit.edu',
  }

  if ($purge_config) {
    resources { 'puppet_config':
      purge => true,
    }
  }

  #Exec["apt_update"] -> Package <| title != 'software-properties-common' |>
}
