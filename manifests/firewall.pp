class rke2::firewall (
  Boolean $enabled,
  Optional[Enum['ufw', 'firewalld']] $provider,
){
  $plane_ifaces = [
    "flannel.${$rke2::vxlan_id}",
    "cni0",
  ]

  $plane_ports = [
    {
      'port'     => '2379:2380',
      'protocol' => 'tcp',
    },
    {
      'port'     => '6443',
      'protocol' => 'tcp',
    },
    {
      'port'     => '9345',
      'protocol' => 'tcp',
    },
    {
      'port'     => '8472',
      'protocol' => 'udp',
    },
    {
      'port'     => '10250',
      'protocol' => 'tcp',
    },
    {
      'port'     => '51820',
      'protocol' => 'udp',
    },
    {
      'port'     => '51821',
      'protocol' => 'udp',
    },
  ]

  $provider_actual = if ! $enabled {
    undef
  } elsif $provider {
    $provider
  } elsif $facts['rke2_ufw_present'] {
    'ufw'
  } elsif $facts['rke2_firewalld_present'] {
    'firewalld'
  }

  case $provider_actual {
    'ufw':       { contain 'rke2::firewall::ufw' }
    'firewalld': { contain 'rke2::firewall::firewalld' }
    default:    {}
  }
}
