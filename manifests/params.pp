class puppet::params (
  $version,
  $puppetmaster
) {
  if !$version { $pin_ensure = 'absent' }
  else {  $pin_ensure = 'present' }
}
