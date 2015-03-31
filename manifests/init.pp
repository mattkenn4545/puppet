class puppet (
  $version        = undef,
  $puppetmaster   = 'puppet',
  $purge_config   = true
) {
  apt::source { 'puppetlabs':
    location   => 'http://apt.puppetlabs.com',
    repos      => 'main dependencies',
    key        => '4BD6EC30',
    key_server => 'pgp.mit.edu',
  }

  if ($purge_config) {
    resources { 'puppet_config':
      purge => true,
    }
  }

  Apt::Pin <| |> ~> Exec["apt_update"] -> Package <| title != 'software-properties-common' |>
}
