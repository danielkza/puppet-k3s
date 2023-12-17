class k3s::firewall {
  $plane_ifaces = [
    "flannel.*",
    "cni*",
  ]
  $plane_ports = [
    {
      'port'     => '2379-2380',
      'protocol' => 'tcp',
    },
    {
      'port'     => '6433',
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
}
