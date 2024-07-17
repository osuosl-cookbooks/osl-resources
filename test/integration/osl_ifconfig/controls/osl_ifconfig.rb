control 'osl_ifconfig' do
  %w(eth1 eth2 eth3 eth4 eth5 eth1.172 eth1.10 br172 br10).each do |i|
    describe interface(i) do
      it { should exist }
    end
  end

  # eth1 should be up
  describe command('ip -0 -o addr show dev eth1') do
    its('stdout') { should match /BROADCAST,NOARP,UP,LOWER_UP/ }
  end

  # These interfaces should NOT have an IP address
  %w(eth1 eth1.172 eth1.10 br172).each do |i|
    describe command("ip -4 -o addr show dev #{i}") do
      its('stdout') { should_not match /inet/ }
    end
  end

  # Test Multiple IPs
  describe command('ip -o addr show dev eth5') do
    its('stdout') { should match %r{inet 10.1.30.20/24} }
    its('stdout') { should match %r{inet 10.1.30.21/24} }
    its('stdout') { should match %r{inet6 2001:db8::3/64} }
    its('stdout') { should match %r{inet6 2001:db8::4/64} }
    its('stdout') { should match %r{inet6 2001:db8::5/64} }
  end

  # Test IPv6
  describe command('ip -o addr show dev eth4') do
    its('stdout') { should match %r{inet 172.16.50.10/24} }
    its('stdout') { should match %r{inet6 2001:db8::2/64 scope global} }
  end

  # Ensure these vlans are setup properly
  %w(172 10).each do |v|
    # eth1.V should be up and be tagged on VLAN V
    describe command("ip -d -o link show dev eth1.#{v}") do
      its('stdout') { should match /BROADCAST,NOARP,UP,LOWER_UP/ }
      its('stdout') { should match /vlan.*id #{v} (<REORDER_HDR>)?/ }
    end

    # bridge should be up
    describe command("ip -0 -o addr show dev br#{v}") do
      its('stdout') { should match /BROADCAST,MULTICAST,UP,LOWER_UP/ }
    end

    # Check to make sure the bridge is attached correctly
    describe command("bridge link show dev eth1.#{v}") do
      its('stdout') { should match /eth1.#{v}@eth1: <BROADCAST,NOARP,UP,LOWER_UP> mtu 1500 master br#{v}/ }
    end
  end

  # br10 should have an IP address
  describe command('ip -4 -o addr show dev br10') do
    its('stdout') { should match %r{inet 172.16.18.1/24} }
  end

  # bonding tests
  %w(eth2 eth3).each do |i|
    describe command("ip -d -o link show dev #{i}") do
      its('stdout') { should match /BROADCAST,NOARP,SLAVE,UP,LOWER_UP>.*master bond0/ }
    end
  end

  describe interface('bond0') do
    it { should exist }
  end

  describe command('ip -4 -o addr show dev bond0') do
    its('stdout') { should match %r{inet 172.16.20.10/24} }
  end

  describe file('/proc/net/bonding/bond0') do
    [
      /Bonding Mode: load balancing \(round-robin\)\nMII Status: up/,
      /Slave Interface: eth2\nMII Status: up/,
      /Slave Interface: eth3\nMII Status: up/,
    ].each do |r|
      its('content') { should match r }
    end
  end

  # osl_fakenic tests
  # IPv4 only
  describe interface 'eth6' do
    its('ipv4_cidrs') { should include %r{192.168.0.100/24} }
  end

  # IPv6 only
  describe interface 'eth7' do
    its('ipv6_cidrs') { should include %r{2001:db8::6/64} }
  end

  # IPv4 & IPv6
  describe interface 'eth8' do
    its('ipv4_cidrs') { should include %r{192.168.1.100/24} }
    its('ipv6_cidrs') { should include %r{2001:db8::7/64} }
  end

  describe command 'ip -0 -o addr show dev eth8' do
    its('stdout') { should match /MULTICAST/ }
    its('stdout') { should match /00:1a:4b:a6:a7:c4/ }
  end
end
