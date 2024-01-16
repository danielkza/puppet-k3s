class rke2::firewall::firewalld () {
  include 'firewalld'

  $node_ip_iface = $rke2::node_ip_iface ? {
    "auto"  => $facts['networking']['primary'],
    "none"  => undef,
    default => $rke2::node_ip_iface,
  }

  $sources = [
    $rke2::plane_cidr_v4,
    $rke2::plane_cidr_v6,
  ].filter |$v| { !empty($v) }

  firewalld_zone { 'rke2-plane':
    ensure  => present,
    target  => 'default',
    sources => $sources,
  }

  firewalld_zone { 'rke2-cluster':
    ensure     => present,
    target     => 'ACCEPT',
    interfaces => $rke2::firewall::plane_ifaces,
  }

  firewalld_custom_service { 'rke2':
    short       => 'rke2',
    description => 'rke2',
    ports       => $rke2::firewall::plane_ports,
  }

  firewalld_service { 'rke2-plane-rke2':
    ensure  => 'present',
    service => 'rke2',
    zone    => 'rke2-plane',
  }
}
