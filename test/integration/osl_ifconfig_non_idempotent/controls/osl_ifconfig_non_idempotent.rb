control 'osl_ifconfig_non_idempotent' do
  %w(eth1 eth2).each do |i|
    describe interface(i) do
      it { should exist }
    end
  end

  # eth1 & eth2 should be down
  %w(eth1 eth2).each do |int|
    describe command("ip -0 -o addr show dev #{int}") do
      its('stdout') { should_not match /BROADCAST,NOARP,UP,LOWER_UP/ }
      its('stdout') { should match /state DOWN/ }
    end
  end

  # eth3 should be up
  describe command('ip -0 -o addr show dev eth3') do
    its('stdout') { should match /BROADCAST,NOARP,UP,LOWER_UP/ }
  end

  # Test disable
  describe command('ip -o addr show dev eth1') do
    its('stdout') { should_not match %r{inet 10.1.30.20/24} }
  end

  describe file('/etc/sysconfig/network-scripts/ifcfg-eth1') do
    it { should exist }
  end

  # Test delete
  describe command('ip -o addr show dev eth2') do
    its('stdout') { should_not match %r{inet 10.1.30.20/8} }
  end

  describe file('/etc/sysconfig/network-scripts/ifcfg-eth2') do
    it { should exist }
    %w(DEVICE=eth2 ONBOOT=no TYPE=none).each do |p|
      its('content') { should match /^#{p}$/ }
    end
  end

  # Test enable
  describe command('ip -o addr show dev eth3') do
    its('stdout') { should match %r{inet 10.1.1.20/24} }
  end
end
