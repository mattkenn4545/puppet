class puppet::puppetmaster ( $git_ssh_key ) {
  package { 'puppetmaster-passenger':
    ensure  => installed,
    require => Apt::Source[ 'puppetlabs' ],
    before  => Package[ 'puppet' ],
  }

  host { 'puppet':
    ensure  => present,
    ip      => '127.0.1.1',
    before  => Package[ 'puppet' ],
  }

  if !defined(Package[ 'git' ]) {
    package { 'git':
      ensure => installed,
    }
  }

  user { 'git':
    ensure      => present,
    managehome  => true,
  }

  file { '/etc/puppet/environments':
    ensure => directory,
    mode    => '0755',
    owner   => 'git',
    group   => 'git',
    require => [ User[ 'git' ], Package[ 'puppet' ] ],
  }

  file { '/opt/puppet.git':
    ensure => directory,
    mode    => '0755',
    owner   => 'git',
    group   => 'git',
    require => User[ 'git' ],
  }

  exec { 'git --bare init':
    cwd     => '/opt/puppet.git',
    creates => '/opt/puppet.git/description',
    user    => 'git',
    require => [ File[ '/opt/puppet.git' ], Package[ 'git' ] ],
  }

  file { '/home/git/.ssh':
    ensure  => directory,
    mode    => '0750',
    owner   => 'git',
    group   => 'git',
    require => User[ 'git' ],
  }

  file { 'post-receive':
    ensure  => present,
    mode    => '0755',
    owner   => 'git',
    group   => 'git',
    source  => "puppet:///modules/${module_name}/post-receive",
    path    => "/opt/puppet.git/hooks/post-receive",
    require => [ File[ '/opt/puppet.git' ], Exec[ 'git --bare init' ] ]
  }

  ssh_authorized_key { 'git_ssh_authorized_key':
    ensure    => present,
    type      => ssh-rsa,
    key       => "${git_ssh_key}",
    user      => 'git',
    require   => File[ '/home/git/.ssh' ],
  }
}
