class puppet::slave (
) inherits puppet::params {
  include puppet::master

  puppet_config { 'master/ca': value => false }
}
