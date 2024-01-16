class rke2::firewall::ufw () {
  include 'ufw'

  $rke2::firewall::plane_ports.each |$entry| {
    $port = $entry['port']
    $proto = $entry['protocol']

    $cidrs = delete_undef_values([$rke2::plane_cidr_v4, $rke2::plane_cidr_v6])
    $cidrs.each |$cidr| {
      ufw_rule { "rke2-port-${port}-${proto}":
        action       => 'allow',
        to_ports_app => $port,
        proto        => $proto,
        from_addr    => $cidr,
      }
    }
  }

  $rke2::firewall::plane_ifaces.each |$iface| {
    $iface_title = regsubst($iface, '[^[:alnum:]\-_\.]', '_', 'G')
    ufw_rule { "rke2-vxlan-iface-${iface_title}":
      action => 'allow',
      interface => $iface,
    }
  }
}
