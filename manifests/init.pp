# @summary Interface class to manage rke2 installation
#
# This class is reponsible to call the install or uninstall classes
#
# @example
#   include rke2
#
# @example
#   class { 'rke2':
#     server => false,
#   }
class rke2 (
  Boolean $server,
  String $config_dir,
  String $state_dir,
  String $binary_version,
  String $binary_path,
  Enum['canal', 'cillium', 'calico', 'none'] $cni,
  Boolean $download_images,
  Optional[String] $plane_cidr_v4,
  Optional[String] $plane_cidr_v6,
  Optional[String] $cluster_cidr_v4,
  Optional[String] $cluster_cidr_v6,
  Optional[String] $service_cidr_v4,
  Optional[String] $service_cidr_v6,
  String $node_ip_iface,
  Optional[Integer] $vxlan_id,
  Optional[Sensitive[String[1]]] $token,
  Optional[Sensitive[String[1]]] $agent_token = $token,
  Hash[String, String] $node_taints,
  Hash[String, String] $node_labels,
) {
  $config_path = "${config_dir}/config.yaml"
  $config_yaml_dir = "${config_dir}/config.yaml.d"

  if ! $plane_cidr_v4 and ! $plane_cidr_v6 {
    fail('At least one of $plane_cidr_v4 and $plane_cidr_v6 must be present')
  }
  if ! $cluster_cidr_v4 and ! $cluster_cidr_v6 {
    fail('At least one of $cluster_cidr_v4 and $cluster_cidr_v6 must be present')
  }
  if ! $service_cidr_v4 and ! $service_cidr_v6 {
    fail('At least one of $service_cidr_v4 and $service_cidr_v6 must be present')
  }
}
