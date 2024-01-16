class rke2::prerequisites::network_manager () {
  file { '/etc/NetworkManager/conf.d/10-ignore-rke2-interfaces.conf':
    ensure => file,
    owner => "root",
    group => "root",
    mode  => "0644",
    content => @(EOF),
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:flannel*;interface-name:tunl*;interface-name:vxlan.calico;
EOF
  }

  exec { 'networkmanager-disable-cloud':
    command => 'systemctl mask nm-cloud-setup.service',
    onlyif  => 'systemctl list-unit-files nm-cloud-setup.service',
    unless  => 'systemctl list-unit-files nm-cloud-setup.service | grep -q masked',
    path    => "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin",
  }
}
