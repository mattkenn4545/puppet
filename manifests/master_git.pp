class puppet::master_git (
  $ssh_key  =   undef
) inherits puppet {
  include puppet::master

  if !defined(Package[ 'git' ]) {
    package { 'git':
      ensure => installed
    }
  }

  package { 'librarian-puppet-simple':
    ensure   => 'installed',
    provider => 'gem'
  }

  user { 'git':
    ensure      => present,
    managehome  => true
  }

  file { '/opt/puppet.git':
    ensure => directory,
    mode    => '0755',
    owner   => 'git',
    group   => 'git',
    require => User[ 'git' ]
  }

  exec { 'git --bare init':
    cwd     => '/opt/puppet.git',
    creates => '/opt/puppet.git/description',
    user    => 'git',
    require => [ File[ '/opt/puppet.git' ], Package[ 'git' ] ]
  }

  file { '/home/git/.ssh':
    ensure  => directory,
    mode    => '0750',
    owner   => 'git',
    group   => 'git',
    require => User[ 'git' ]
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
  if ($ssh_key) {
    ssh_authorized_key { 'git_ssh_authorized_key':
      ensure    => present,
      type      => ssh-rsa,
      key       => $ssh_key,
      user      => 'git',
      require   => File[ '/home/git/.ssh' ]
    }
  }
}
