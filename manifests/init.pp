# @summary Interface class to manage k3s installation
#
# This class is reponsible to call the install or uninstall classes
#
# @example
#   include k3s
#
# @example
#   class { 'k3s':
#     installation_mode => 'binary',
#     binary_path       => '/home/john-doe/bin/k3s',
#   }
class k3s (
  String $config_dir,
  String $state_dir,
  String $binary_version,
  String $binary_path,
  Boolean $download_images = true,
) {
  include k3s::prerequisites
  include k3s::install

  $config_path = "${config_dir}/config.yaml"
  $config_yaml_dir = "${config_dir}/config.yaml.d"

  Class['k3s::prerequisites'] -> Class['k3s::install']
}
