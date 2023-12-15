# @summary Class responsible for installing k3s
class k3s::install {
  include k3s::prerequisites

  case $facts['os']['architecture'] {
    'amd64', 'x86_64': {
      $binary_arch = 'k3s'
      $checksum_arch = 'sha256sum-amd64.txt'
    }
    'arm64': {
      $binary_arch = 'k3s-arm64'
      $checksum_arch = 'sha256sum-arm64.txt'
    }
    'armhf': {
      $binary_arch = 'k3s-armhf'
      $checksum_arch = 'sha256sum-arm.txt'
    }
    default: {
      fail('No valid architecture provided.')
    }
  }
  $k3s_url = "https://github.com/rancher/k3s/releases/download/${k3s::binary_version}/${binary_arch}"
  $k3s_checksum_url = "https://github.com/rancher/k3s/releases/download/${k3s::binary_version}/${checksum_arch}"

  archive { $k3s::binary_path:
    ensure           => present,
    source           => $k3s_url,
    checksum_url     => $k3s_checksum_url,
    checksum_type    => 'sha256',
    cleanup          => false,
    download_options => '-S',
    user             => "root",
    group            => "root",
  }

  file { $k3s::binary_path:
    ensure  => file,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => [
      Archive[$k3s::binary_path],
    ],
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

  if $k3s::download_images {
    $k3s_images_url = "https://github.com/rancher/k3s/releases/download/${k3s::binary_version}/k3s-airgap-images-${binary_arch}.tar.zst"
    $image_dir = "${k3s::state_dir}/agent/images"
    $images_file = "${image_dir}/${basename($k3s_images_url)}"

    file { $image_dir:
      ensure => directory,
      owner  => "root",
      group  => "root",
      mode   => "0750",
    }

    archive { 'k3s-images':
      ensure           => present,
      path             => $images_file,
      source           => $k3s_images_url,
      checksum_url     => $k3s_checksum_url,
      checksum_type    => 'sha256',
      cleanup          => false,
      download_options => '-S',
      user             => "root",
      group            => "root",
    }

    file { $images_file:
      ensure  => file,
      owner => "root",
      group => "root",
      mode  => "0640",
    }
  }
}
