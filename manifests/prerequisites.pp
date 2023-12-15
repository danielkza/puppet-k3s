class k3s::prerequisites (
  Array[String] $packages,
) {
  package { $packages:
    ensure => present,
  }
}
