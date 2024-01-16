class rke2::configure (
  Boolean $server = $rke2::server,
  Boolean $purge,
) {
  $role = if $server { 'server' } else { 'agent' }

  $agent_token_file = "${rke2::config_dir}/agent-token"
  file { $agent_token_file:
    ensure => file,
    owner  => "root",
    group  => "root",
    mode   => "0640",
    content => "${unwrap($rke2::agent_token)}\n",
  }

  if $server {
    $token_file = "${rke2::config_dir}/token"
    file { $token_file:
      ensure => file,
      owner  => "root",
      group  => "root",
      mode   => "0640",
      content => "${unwrap($rke2::token)}\n",
    }

    rke2::config::server { 'membership':
      order => 90,
      values => {
        "token-file"       => $token_file,
        "agent-token-file" => $agent_token_file,
      },
    }
  } else {
    rke2::config::agent { 'membership':
      order => 90,
      values => {
        "token-file" => $agent_token_file,
        "server"     => $rke2::server_url,
      },
    }
  }

  $default_taints = if $server and lookup('rke2::server::no_workloads') {
    { "CriticalAddonsOnly" => "true:NoExecute" }
  } else {
    {}
  }
  rke2::config::common { 'labels':
    order => 50,
    values => {
      "node-taints" => $default_taints + $rke2::node_taints,
      "node-labels" => $rke2::node_labels,
    },
  }

  # node-ip
  $node_ip_iface = $rke2::node_ip_iface ? {
    "auto"  => $facts['networking']['primary'],
    "none"  => undef,
    default => $rke2::node_ip_iface,
  }
  if $node_ip_iface {
    $iface_data = $facts['networking']['interfaces'][$node_ip_iface]
    $bindings = $iface_data['bindings'] + $iface_data['bindings6']
    $addresses = $bindings.map |$bd| { $bd['address'] }

    rke2::config::common { 'node-ip':
      order => 50,
      values => {
        "node-ip" => $addresses,
      },
    }
  }

  rke2::config::common { 'cidrs':
    values => {
      "cluster-cidr" => [$rke2::cluster_cidr_v4, $rke2::cluster_cidr_v6].filter |$v| {
        !empty($v)
      },
      "service-cidr" => [$rke2::service_cidr_v4, $rke2::service_cidr_v6].filter |$v| {
        !empty($v)
      },
    },
  }

  $conf_hash = {}
  $config_path = "${rke2::config_dir}/${role}.yaml"
  $conf_file = file { "rke2-${role}-config":
    ensure => file,
    path   => $config_path,
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    content => stdlib::to_yaml($conf_hash, { indentation => 2 }),
  }

  $registries = stdlib::to_yaml({
    mirrors => lookup('rke2::registries::mirrors'),
    configs => lookup('rke2::registries::configs'),
  }, { indentation => 2 })
  file { "rke2-registries":
    ensure  => file,
    path    => "${rke2::config_dir}/registries.yaml",
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $registries,
  }

  if ($purge) {
    File <| title == $rke2::config_yaml_dir |> {
      recurse => true,
      purge   => true,
    }
  }

  # Realize configs
  File <| tag == "rke2::config::common" |> {
    ensure => file,
    owner  => "root",
    group  => "root",
    mode   => "0640",
    before => $conf_file,
  }

  File <| tag == "rke2::config::${role}" |> {
    ensure => file,
    owner  => "root",
    group  => "root",
    mode   => "0640",
    before => $conf_file,
  }

  $env_dir = if $facts['os']['family'] in ['RedHat', 'Suse'] {
    '/etc/sysconfig'
  } else {
    '/etc/default'
  }

  $env_file = file { "rke2-${role}-env":
    ensure => file,
    path   => "${env_dir}/rke2-${role}",
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
    content => epp("rke2/rke2-${role}.env"),
  }
  $unit_file = systemd::unit_file { "rke2-${role}.service":
    content => epp("rke2/rke2-${role}.service.epp"),
  }

  service { "rke2-${role}":
    enable => true,
    subscribe => [$env_file, $unit_file, $conf_file],
  }
}
