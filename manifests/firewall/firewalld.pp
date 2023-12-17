class k3s::firewall::firewalld () {
  include 'firewalld'

  firewalld_zone { 'k3s-plane':
    ensure           => present,
    target           => '%%REJECT%%',
    sources          => [
      $k3s_plane_cidr_v4,
      $k3s_plane_cidr_v6,
    ],
  }

  firewalld_zone { 'k3s-cluster':
    ensure     => present,
    target     => '%%ACCEPT%%',
    interfaces => $plane_ifaces,
  }

  firewalld_custom_service { 'k3s':
    short       => 'k3s',
    description => 'k3s',
    ports       => $plane_ports,
  }

  firewalld_service { 'k3s-plane-k3s':
    ensure  => 'present',
    service => 'k3s',
    zone    => 'k3s-plane',
  }
}
