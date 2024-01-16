class rke2::install {
  include rke2
  include rke2::prerequisites

  case $facts['os']['architecture'] {
    'amd64', 'x86_64': {
      $image_arch = 'amd64'
      $checksum_arch = 'sha256sum-amd64.txt'
    }
    'arm64', 'aarch64': {
      $image_arch = 'r'
      $checksum_arch = 'sha256sum-arm64.txt'
    }
    default: {
      fail('No valid architecture provided.')
    }
  }

  # uriescape from stdlib is deprecated, do a weird hack
  $binary_version_esc = regsubst($rke2::binary_version, '\+', '%2B')

  $rke2_base_url = "https://github.com/rancher/rke2/releases/download/${binary_version_esc}"
  $rke2_bin_name = "rke2.linux-${image_arch}"
  $rke2_binary_url = "${rke2_base_url}/${rke2_bin_name}"
  $rke2_checksum_url = "${rke2_base_url}/${checksum_arch}"

  $cache_dir = "/var/cache/puppet-rke2/${rke2::binary_version}"
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
    source  => $rke2_checksum_url,
  }

  archive { 'rke2-binary':
    ensure           => present,
    path             => "${cache_dir}/${rke2_bin_name}",
    source           => $rke2_binary_url,
    cleanup          => false,
    download_options => '-S',
    user             => "root",
    group            => "root",

    notify => Exec['rke2-verify-checksums'],
  }

  exec { 'rke2-verify-checksums':
    command => ['sha256sum', '-c', '--ignore-missing', $checksum_arch],
    path    => '/usr/bin:/bin',
    cwd     => $cache_dir,
  }

  file { $rke2::binary_path:
    ensure  => file,
    source  => "${cache_dir}/${rke2_bin_name}",
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => [
      Exec['rke2-verify-checksums'],
    ],
  }

  $state_dir_parent = dirname($rke2::state_dir)
  if dirname($state_dir_parent) != '/' {
    ensure_resource('file', $state_dir_parent, {
      ensure => directory,
      mode   => '0750',
      owner  => 'root',
      group  => 'root',
    })
  }
  file { [$rke2::state_dir, "${rke2::state_dir}/agent"]:
    ensure => directory,
    owner  => "root",
    group  => "root",
    mode   => "0750",
  }

  if $rke2::download_images {
    $image_dir = "${rke2::state_dir}/agent/images"

    file { $image_dir:
      ensure => directory,
      owner  => "root",
      group  => "root",
      mode   => "0750",
    }

    $image_components = ['core', $rke2::cni]
    $image_components.each |$component| {
      $rke2_images_url = "${rke2_base_url}/rke2-images-${component}.linux-${image_arch}.tar.zst"
      $image_dl_file = "${cache_dir}/${rke2::binary_version}/${basename($rke2_images_url)}"

      archive { "rke2-images-${component}":
        ensure           => present,
        path             => $image_dl_file,
        source           => $rke2_images_url,
        cleanup          => false,
        download_options => '-S',
        user             => "root",
        group            => "root",

        notify => Exec['rke2-verify-checksums'],
      }

      $image_file = "${image_dir}/${basename($rke2_images_url)}"
      file { $image_file:
        ensure  => file,
        source  => $image_dl_file,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        require => [
          Exec['rke2-verify-checksums'],
        ],
      }
    }
  }

  file { '/etc/default/rke2':
    ensure => file,
    mode   => '0640',
    owner  => 'root',
    group  => 'root',
    content => inline_template(@(EOF)
RKE2_CONFIG_FILE="<%= scope['rke2::config_path'] %>"
EOF
    ),
  }

  $config_parent = dirname($rke2::config_dir)
  if dirname($config_parent) != '/' {
    ensure_resource('file', $config_parent, {
      ensure => directory,
      mode   => '0750',
      owner  => 'root',
      group  => 'root',
    })
  }

  file { $rke2::config_dir:
    ensure => directory,
    mode   => '0750',
    owner  => 'root',
    group  => 'root',
  }

  file { $rke2::config_yaml_dir:
    ensure => directory,
    mode   => '0750',
    owner  => 'root',
    group  => 'root',
  }
}
