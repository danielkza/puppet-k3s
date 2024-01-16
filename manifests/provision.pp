class rke2::provision () {
  include rke2::prerequisites
  include rke2::install
  include rke2::firewall
  include rke2::configure

  Class['rke2::prerequisites']
  -> Class['rke2::install']
  -> Class['rke2::firewall']
  -> Class['rke2::configure']
}
