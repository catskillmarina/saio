# == Class: saio
#
# Full description of class saio here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { saio:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Your name here, unless otherwise noted.
#
class saio {

  Apt::Key['ubuntu_cloud_archive'] -> Apt::Source<| |>
  Apt::Key['swift_core'] -> Apt::Source<| |>
  Apt::Source<| |> -> Package<| |>
  Package["libaugeas-ruby"] -> Augeas <| |>

  apt::key { 'ubuntu_cloud_archive':
    key        => 'EC4926EA',
    key_server => 'keyserver.ubuntu.com',
  }
  apt::source { 'ubuntu_cloud_archive':
    location          => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
    release           => 'precise-updates/folsom',
    repos             => 'main',
    key               => 'EC4926EA',
    key_server        => 'keyserver.ubuntu.com',
    include_src       => true
  }
  apt::key { 'swift_core':
    key        => '562598B4',
    key_server => 'keyserver.ubuntu.com',
  }
  apt::source { 'swift_core':
    location          => 'http://ppa.launchpad.net/swift-core/release/ubuntu',
    release           => 'precise',
    repos             => 'main',
    key               => '562598B4',
    key_server        => 'keyserver.ubuntu.com',
    include_src       => true
  }
  package { 'ntfs-3g':
    ensure  => 'absent',
  }
  package { 'python-software-properties':
    ensure  => 'latest',
  }
  package { 'git':
    ensure  => 'latest',
  }
  package { ['nfs-common','rpcbind']:
    ensure  => 'absent',
  }
  package { 'libaugeas-ruby':
    ensure  => 'latest',
  }
  package { 'augeas-tools':
    ensure  => 'latest',
  }
  package { 'chkconfig':
    ensure  => 'latest',
  }
  package { 'finger':
    ensure  => 'latest',
  }
  package { 'vim-puppet':
    ensure  => 'latest',
  }
  package { ['curl', 'gcc', 'git-core', 'python-coverage', 
    'python-dev', 'python-nose', 'python-setuptools', 'python-simplejson', 
    'python-xattr', 'sqlite3', 'xfsprogs', 'python-eventlet', 
    'python-greenlet', 'python-pastedeploy', 'python-netifaces', 'python-pip']:
    ensure  => 'latest',
  }
  # These packages are missing from the saio documentation for ubuntu
  package { [ 'python-swift','python-swiftclient','python2.7-swift',
    'swift','swift-account','swift-container','swift-doc',
    'swift-object','swift-plugin-s3','swift-proxy']:
    ensure  => 'latest',
  }
  package { 'memcached':
    ensure  => 'latest',
  }
  service { 'memcached':
    ensure  => 'running',
    require => Package['memcached'],
  }
# Package["libaugeas-ruby"] -> Augeas <| |>
  package { 'rsync':
    ensure  => 'latest',
  }
  augeas { 'rsync-default':
    context   => '/files/etc/default/rsync',
    onlyif    => "get RSYNC_ENABLE != \'true\'",
    changes   => "set RSYNC_ENABLE \'true\'",
  }
  file { '/etc/rsyncd.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/rsyncd.conf',
    notify    => Service['rsync'],
  }
  service { 'rsyslog':
    ensure    => 'running',
  }
  file { '/etc/rsyslog.d/10-swift.conf':
    ensure    => 'file',
    content   => 'puppet:///modules/saio/10-swift.conf',
    notify    => Service['rsyslog'],
  }
  exec { "sed -i 's/PrivDropToGroup syslog/PrivDropToGroup adm/' /etc/rsyslog.conf":
    alias     => 'change_syslog_to_adm_in_rsyslog',
    onlyif    => 'grep "PrivDropToGroup adm" /etc/rsyslog.conf | wc -l|grep 0',
    notify    => Service['rsyslog'],
  }
  file { '/var/log/swift':
    ensure    => 'directory',
    owner     => 'root',
    group     => 'adm',
    mode      => '0775',
    notify    => Service['rsyslog'],
  }
  file { '/var/log/swift/hourly':
    ensure    => 'directory',
    owner     => 'root',
    group     => 'adm',
    mode      => '0775',
    notify    => Service['rsyslog'],
  }
  service { 'rsync':
    ensure    => 'running',
    require   => File['/etc/rsyncd.conf'],
  }
  augeas { 'net.ipv4.tcp_tw_recycle':
    context   => '/files/etc/sysctl.conf',
    onlyif    => "get net.ipv4.tcp_tw_reuse != 1",
    changes   => "set net.ipv4.tcp_tw_reuse 1",
  }
  augeas { 'net.ipv4.tcp_tw_reuse':
    context   => '/files/etc/sysctl.conf',
    onlyif    => "get net.ipv4.tcp_tw_reuse != 1",
    changes   => "set net.ipv4.tcp_tw_reuse 1",
  }
  augeas { 'disable syn cookies':
    context   => '/files/etc/sysctl.conf',
    onlyif    => 'get net.ipv4.tcp_syncookies != 0',
    changes   => 'set net.ipv4.tcp_syncookies 0',
  }
  augeas { 'double amount of allowed conntrack':
    context   => '/files/etc/sysctl.conf',
    onlyif    => 'get net.ipv4.netfilter.ip_conntrack_max != 26214',
    changes   => 'set net.ipv4.netfilter.ip_conntrack_max 26214',
  }
  file { '/srv/':
    ensure    => 'directory',
    owner     => 'root',
    group     => 'root',
    mode      => '0755',
  }
  file { '/mnt/swift':
    ensure    => 'directory',
    owner     => 'root',
    group     => 'root',
    mode      => '0755',
  }
  # Edit /etc/fstab and add
  # /dev/sdb1 /mnt/sdb1 xfs noatime,nodiratime,nobarrier,logbufs=8 0 0
  exec { 'dd if=/dev/zero of=/srv/loopfile bs=1024 count=1024000':
    alias     => 'zero_diskfile',
    creates   => '/srv/loopfile',
    onlyif    => 'ls /srv/loopfile | wc -l |grep 0'
  }
  exec { 'losetup /dev/loop0 /srv/loopfile':
    alias     => 'configure_diskfile',
    onlyif    => 'mount | grep \'/dev/loop0\' | wc -l | grep 0'
  }
  exec { 'mkfs -t xfs /dev/loop0':
    alias     => 'format_diskfile',
    onlyif    => 'mount | grep \'/dev/loop0\' | wc -l | grep 0',
  }
  exec { 'mount -t xfs /dev/loop0 /mnt/swift':
    alias     => 'mount_diskfile',
    onlyif    => 'mount | grep \'/dev/loop0\' | wc -l | grep 0',
  }
  file { '/mnt/swift/1':
    ensure    => 'directory',
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/srv/1':
    ensure    => 'link',
    target    => '/mnt/swift/1',
    subscribe => File['/mnt/swift/1'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/srv/1/node':
    ensure    => 'directory',
    subscribe => File['/srv/1'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/srv/1/node/sdb-1':
    ensure    => 'directory',
    subscribe => File['/srv/1/node'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/mnt/swift/2':
    ensure    => 'directory',
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/srv/2':
    ensure    => 'link',
    target    => '/mnt/swift/2',
    subscribe => File['/mnt/swift/2'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/srv/2/node':
    ensure    => 'directory',
    subscribe => File['/srv/2'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0777',
  }
  file { '/srv/2/node/sdb-2':
    ensure    => 'directory',
    subscribe => File['/srv/2/node'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/mnt/swift/3':
    ensure    => 'directory',
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/srv/3':
    ensure    => 'link',
    target    => '/mnt/swift/3',
    subscribe => File['/mnt/swift/3'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/srv/3/node':
    ensure    => 'directory',
    subscribe => File['/srv/3'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/srv/3/node/sdb-3':
    ensure    => 'directory',
    subscribe => File['/srv/3/node'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/mnt/swift/4':
    ensure    => 'directory',
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/srv/4':
    ensure    => 'link',
    target    => '/mnt/swift/4',
    subscribe => File['/mnt/swift/4'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/srv/4/node':
    ensure    => 'directory',
    subscribe => File['/srv/4'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/srv/4/node/sdb-4':
    ensure    => 'directory',
    subscribe => File['/srv/4/node'],
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/var/run/swift':
    ensure    => 'directory',
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/etc/motd':
    ensure    => 'file',
    content   => 'Welcome to your Vagrant-built virtual machine!
              Managed by Puppet.

Swift development code is in /opt/
Be sure to source /etc/bash.bashrc
'
  }
  file { '/usr/local/admin':
    ensure    => 'directory',
    owner     => 'root',
    group     => 'root',
    mode      => '755',
  }
  file { '/usr/local/admin/bin':
    ensure    => 'directory',
    owner     => 'root',
    group     => 'root',
    mode      => '755',
    require   => File['/usr/local/admin'],
  }
  exec { "echo 'export SWIFT_TEST_CONFIG_FILE=/etc/swift/test.conf' >> /etc/bash.bashrc":
    onlyif    => 'grep SWIFT_TEST_CONFIG_FILE /etc/bash.bashrc| wc -l|grep 0',
  }
  exec { "echo 'export SWIFT_TEST_CONFIG_FILE=/etc/swift/test.conf' >> /root/.bashrc":
    onlyif    => 'grep SWIFT_TEST_CONFIG_FILE /root/.bashrc| wc -l|grep 0',
  }
  file { '/opt/swift':
    ensure    => 'directory',
    mode      => '0755',
    owner     => 'root',
  }
  file { '/opt/swiftclient':
    ensure    => 'directory',
    mode      => '0755',
    owner     => 'root',
  }
  vcsrepo { '/opt/swift':
    ensure    => present,
    provider  => git,
    source    => 'https://github.com/openstack/swift.git',
    revision  => 'master',
  }
  vcsrepo { '/opt/swiftclient':
    ensure    => present,
    provider  => git,
    source    => 'https://github.com/openstack/python-swiftclient.git',
    revision  => 'master',
  }
# exec { 'setup_swift_devel':
#   command   => 'python setup.py develop',
#   path      => '/opt/swift/bin:/usr/bin:/bin:/usr/sbin',
#   onlyif    => 'ls /opt/swift/swift/__init__.pyc|wc -l|grep 0',
#   cwd       => '/opt/swift',
# }
# exec { 'setup_swiftclient_develop':
#   command   => 'python setup.py develop',
#   path      => '/opt/swift/bin:/usr/bin:/bin:/usr/sbin',
#   onlyif    => 'ls /opt/swiftclient/swiftclient/__init__.pyc|wc -l|grep 0',
#   cwd       => '/opt/swiftclient',
# }
  service { 'swift-proxy':
    ensure    => 'running',
  }
  file { '/etc/swift/proxy-server.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/proxy-server.conf',
    notify    => Service['swift-proxy'],
  }
# service { 'swift':
#   ensure    => 'running',
# }
  file { '/etc/swift/swift.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/swift.conf',
#   notify    => Service['swift'],
  }
  service { 'swift-account':
    ensure    => 'running',
  }
  file { '/etc/swift/account-server':
    ensure    => 'directory',
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  # consolidate these into one template with variables #
  file { '/etc/swift/account-server/1.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/account-server_1.conf',
    require   => File['/etc/swift/account-server'],
    notify    => Service['swift-account'],
  }
  file { '/etc/swift/account-server/2.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/account-server_2.conf',
    require   => File['/etc/swift/account-server'],
    notify    => Service['swift-account'],
  }
  file { '/etc/swift/account-server/3.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/account-server_3.conf',
    require   => File['/etc/swift/account-server'],
    notify    => Service['swift-account'],
  }
  file { '/etc/swift/account-server/4.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/account-server_4.conf',
    require   => File['/etc/swift/account-server'],
    notify    => Service['swift-account'],
  }
  service { 'swift-account-auditor':
    ensure    => 'running',
  }
  service { 'swift-account-reaper':
    ensure    => 'running',
  }
  service { 'swift-account-replicator':
    ensure    => 'running',
  }
  service { 'swift-container':
    ensure    => 'running',
  }
  service { 'swift-container-auditor':
    ensure    => 'running',
  }
  service { 'swift-container-replicator':
    ensure    => 'running',
  }
  service { 'swift-container-updater':
    ensure    => 'running',
  }
  file { '/etc/swift/container-server':
    ensure    => 'directory',
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/etc/swift/container-server/1.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/container-server_1.conf',
    require   => File['/etc/swift/container-server'],
    notify    => Service['swift-container'],
  }
  file { '/etc/swift/container-server/2.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/container-server_2.conf',
    require   => File['/etc/swift/container-server'],
    notify    => Service['swift-container'],
  }
  file { '/etc/swift/container-server/3.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/container-server_3.conf',
    require   => File['/etc/swift/container-server'],
    notify    => Service['swift-container'],
  }
  file { '/etc/swift/container-server/4.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/container-server_4.conf',
    require   => File['/etc/swift/container-server'],
    notify    => Service['swift-container'],
  }
  service { 'swift-object':
    ensure    => 'running',
  }
  service { 'swift-object-auditor':
    ensure    => 'running',
  }
  service { 'swift-object-replicator':
    ensure    => 'running',
  }
  service { 'swift-object-updater':
    ensure    => 'running',
  }
  file { '/etc/swift/object-server':
    ensure    => 'directory',
    owner     => 'swift',
    group     => 'swift',
    mode      => '0755',
  }
  file { '/etc/swift/object-server/1.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/object-server_1.conf',
    require   => File['/etc/swift/object-server'],
    notify    => Service['swift-object'],
  }
  file { '/etc/swift/object-server/2.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/object-server_2.conf',
    require   => File['/etc/swift/object-server'],
    notify    => Service['swift-object'],
  }
  file { '/etc/swift/object-server/3.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/object-server_3.conf',
    require   => File['/etc/swift/object-server'],
    notify    => Service['swift-object'],
  }
  file { '/etc/swift/object-server/4.conf':
    ensure    => 'file',
    source    => 'puppet:///modules/saio/object-server_4.conf',
    require   => File['/etc/swift/object-server'],
    notify    => Service['swift-object'],
  }
  file { '/usr/local/admin/sbin/':
    ensure    => 'directory',
    mode      => '0755',
  }
  file { '/usr/local/admin/sbin/remakerings.sh':
    ensure    => 'file',
    mode      => '0755',
    source    => 'puppet:///modules/saio/remakerings.sh',
    require   => File['/usr/local/admin/sbin/'],
  }
}
