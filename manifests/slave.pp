class puppet::slave (
) inherits puppet {
  include puppet::master

  puppet_config { 'master/ca': value => false }
}
