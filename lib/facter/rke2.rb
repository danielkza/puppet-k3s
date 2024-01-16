Facter.add(:rke2_networkmanager_present) do
  confine :kernel => 'Linux'

  setcode do
    File.exist?('/etc/NetworkManager/NetworkManager.conf')
  end
end

Facter.add(:rke2_ufw_present) do
  confine :kernel => 'Linux'
  setcode do
    Facter::Core::Execution.which('ufw') != nil
  end
end

Facter.add(:rke2_firewalld_present) do
  confine :kernel => 'Linux'
  setcode do
    Facter::Core::Execution.which('firewalld') != nil
  end
end
