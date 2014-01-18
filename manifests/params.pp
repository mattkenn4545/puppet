class puppet::params (
  $version
) {
  if !$version { $pin_ensure = 'absent' }
  else {  $pin_ensure = 'present' }
}
