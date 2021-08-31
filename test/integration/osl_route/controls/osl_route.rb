control 'osl_route' do
  # test route configs and files
  describe file('/etc/sysconfig/network-scripts/route-eth1') do
    [
      /^ADDRESS0=10\.50\.0\.0$/,
      /^NETMASK0=255\.255\.254\.0$/,
      /^GATEWAY0=10\.30\.0\.1$/,
    ].each do |line|
      its('content') { should match line }
    end
  end

  describe file('/etc/sysconfig/network-scripts/route-eth2') do
    [
      /^ADDRESS0=10\.60\.0\.0$/,
      /^NETMASK0=255\.255\.254\.0$/,
      /^ADDRESS1=10\.70\.0\.0$/,
      /^NETMASK1=255\.255\.254\.0$/,
      /^GATEWAY1=10\.40\.0\.1$/,
    ].each do |line|
      its('content') { should match line }
    end
    its('content') { should_not match(/^GATEWAY0/) }
  end

  describe file('/etc/sysconfig/network-scripts/route-eth3') do
    it { should_not exist }
  end

  describe command('ip route') do
    its('stdout') { should match %r{^10\.50\.0\.0\/23 via 10\.30\.0\.1.*eth1} }
    its('stdout') { should match %r{^10\.60\.0\.0\/23.*eth2} }
    its('stdout') { should match %r{^10\.70\.0\.0\/23 via 10\.40\.0\.1.*eth2} }
    its('stdout') { should_not match /eth3/ }
  end

  # test interface config and files
  [
    ['eth1', /10\.30\.0\.1/],
    ['eth2', /10\.40\.0\.1/],
  ].each do |iface, addr|
    describe file("/etc/sysconfig/network-scripts/ifcfg-#{iface}") do
      [
        /^IPADDR=#{addr}$/,
        /^NETMASK=255\.255\.255\.0$/,
        /^DEVICE=#{iface}$/,
      ].each do |line|
        its('content') { should match line }
      end
    end
    describe command("ip -o addr show #{iface}") do
      its('stdout') { should match /#{iface}.*inet #{addr}/ }
    end
  end
end
