class rke2::prerequisites (
  Array[String] $packages,
) {
  package { $packages:
    ensure => present,
  }

  if $facts['rke2_networkmanager_present'] {
    include 'rke2::prerequisites::network_manager'
  }
}
