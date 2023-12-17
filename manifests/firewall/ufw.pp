class k3s::firewall::ufw () {
  include 'ufw'

  $k3s::firewall::plane_ports.each |$entry| {
    $port = $entry['port']
    $proto = $entry['protocol']

    [$k3s::plane_cidr_v4, $k3s::plane_cidr_v6].each |$cidr| {
      ufw_rule { "k3s-port-${port}-${proto}":
        action       => 'allow',
        to_ports_app => $port,
        proto        => $proto,
        from_addr    => $cidr,
      }
    }
  }

  $k3s::firewall::plane_ifaces.each |$iface| {
    ufw_rule { "k3s-vxlan-iface-${iface}":
      action => 'allow',
      interface => $iface,
    }
  }
}
