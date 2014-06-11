class puppet (
  $version        = hiera('puppet::version', undef),
  $puppetmaster   = 'puppet'
) {
  class { 'puppet::params':
    version   => $version
  }

  apt::source { 'puppetlabs':
    location   => 'http://apt.puppetlabs.com',
    repos      => 'main dependencies',
    key        => '4BD6EC30',
    key_server => 'pgp.mit.edu',
  }

  Apt::Pin <| |> ~> Exec["apt_update"]  -> Package <| |>
}
