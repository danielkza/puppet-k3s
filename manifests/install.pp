# @summary Class responsible for installing k3s
class k3s::install {
  include k3s::prerequisites

  case $facts['os']['architecture'] {
    'amd64', 'x86_64': {
      $binary_arch = 'k3s'
      $image_arch = 'amd64'
      $checksum_arch = 'sha256sum-amd64.txt'
    }
    'arm64', 'aarch64': {
      $binary_arch = 'k3s-arm64'
      $image_arch = 'arm64'
      $checksum_arch = 'sha256sum-arm64.txt'
    }
    'armhf': {
      $binary_arch = 'k3s-armhf'
      $image_arch = 'armhf'
      $checksum_arch = 'sha256sum-arm.txt'
    }
    default: {
      fail('No valid architecture provided.')
    }
  }

  # uriescape from stdlib is deprecated, do a weird hack
  $binary_version_esc = regsubst($k3s::binary_version, '\+', '%2B')

  $k3s_base_url = "https://github.com/k3s-io/k3s/releases/download/${binary_version_esc}"
  $k3s_binary_url = "${k3s_base_url}/${binary_arch}"
  $k3s_checksum_url = "${k3s_base_url}/${checksum_arch}"

  $cache_dir = "/var/cache/puppet-k3s/${k3s::binary_version}"
  file { [dirname($cache_dir), $cache_dir]:
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  file { "${cache_dir}/${checksum_arch}":
    ensure  => file,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    source  => $k3s_checksum_url,
  }

  archive { 'k3s-binary':
    ensure           => present,
    path             => "${cache_dir}/${binary_arch}",
    source           => $k3s_binary_url,
    cleanup          => false,
    download_options => '-S',
    user             => "root",
    group            => "root",

    notify => Exec['k3s-verify-checksums'],
  }

  exec { 'k3s-verify-checksums':
    command => ['sha256sum', '-c', '--ignore-missing', $checksum_arch],
    path    => '/usr/bin:/bin',
    cwd     => $cache_dir,
  }

  file { $k3s::binary_path:
    ensure  => file,
    source  => "${cache_dir}/${binary_arch}",
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => [
      Exec['k3s-verify-checksums'],
    ],
  }

  $state_dir_parent = dirname($k3s::state_dir)
  if dirname($state_dir_parent) != '/' {
    ensure_resource('file', $state_dir_parent, {
      ensure => directory,
      mode   => '0750',
      owner  => 'root',
      group  => 'root',
    })
  }
  file { [$k3s::state_dir, "${k3s::state_dir}/agent"]:
    ensure => directory,
    owner  => "root",
    group  => "root",
    mode   => "0750",
  }

  if $k3s::download_images {
    $k3s_images_url = "${k3s_base_url}/k3s-airgap-images-${image_arch}.tar.zst"
    $image_dl_file = "${cache_dir}/${basename($k3s_images_url)}"

    $image_dir = "${k3s::state_dir}/agent/images"
    $image_file = "${image_dir}/${basename($k3s_images_url)}"

    file { $image_dir:
      ensure => directory,
      owner  => "root",
      group  => "root",
      mode   => "0750",
    }

    archive { 'k3s-images':
      ensure           => present,
      path             => $image_dl_file,
      source           => $k3s_images_url,
      cleanup          => false,
      download_options => '-S',
      user             => "root",
      group            => "root",

      notify => Exec['k3s-verify-checksums'],
    }

    file { $image_file:
      ensure  => file,
      source  => $image_dl_file,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      require => [
        Exec['k3s-verify-checksums'],
      ],
    }
  }

  file { '/etc/default/k3s':
    ensure => file,
    mode   => '0640',
    owner  => 'root',
    group  => 'root',
    content => inline_template(@(EOF)
K3S_CONFIG_FILE="<%= scope['k3s::config_path'] %>"
EOF
    ),
  }

  $config_parent = dirname($k3s::config_dir)
  if dirname($config_parent) != '/' {
    ensure_resource('file', $config_parent, {
      ensure => directory,
      mode   => '0750',
      owner  => 'root',
      group  => 'root',
    })
  }

  file { $k3s::config_dir:
    ensure => directory,
    mode   => '0750',
    owner  => 'root',
    group  => 'root',
  }

  file { $k3s::config_yaml_dir:
    ensure => directory,
    mode   => '0750',
    owner  => 'root',
    group  => 'root',
  }
}
