# This control must pass immediately after a converge AND after a manual
# reboot of the converged node. Reboot survival comes from two mechanisms:
# the osl_fakenic units recreate the dummy parents before NetworkManager
# starts, and the NetworkManager profiles `nmstatectl apply` wrote reconfigure
# everything on top of them. /etc/nmstate/*.yml is inert once applied and
# proves nothing here.
#
# AlmaLinux 8 is converge-only: ifup has no boot-time counterpart, since
# network.service ships disabled, and NM's ifcfg reader does not understand
# TYPE=dummy.
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

  # An admin-down interface still carrying addresses passes every `ip addr`
  # assertion below, so check the link itself.
  %w(eth4 eth5 eth9).each do |i|
    describe command("ip -0 -o link show dev #{i}") do
      its('stdout') { should match /,UP,/ }
      its('stdout') { should match /state (UP|UNKNOWN)/ }
    end
  end

  # A missing mask used to render a silent /32 with no on-link subnet route.
  describe command('ip -4 -o addr show dev eth9') do
    its('stdout') { should match %r{inet 172.16.51.11/24} }
    its('stdout') { should_not match %r{inet 172.16.51.11/32} }
  end

  describe command('ip -0 -o link show dev eth9') do
    its('stdout') { should match /mtu 1400/ }
    # hwaddr sets the MAC only on nmstate, so the fixture omits it on EL8.
    its('stdout') { should match /00:1a:4b:a6:a7:c9/ } if os.release.to_i >= 9
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

  # br44 never lists eth11; eth11 names br44. Regression test for controller:.
  describe interface('br44') do
    it { should exist }
  end

  describe command('bridge link show dev eth11') do
    its('stdout') { should match /master br44/ }
  end

  # `delay '0'` was dropped on nmstate, leaving NM's 15s forward delay, so
  # these bridges spent ~30s non-forwarding after boot. nmstate refuses
  # forward-delay 0 (range 2-30), so it maps to STP off.
  %w(br10 br172 br44).each do |b|
    describe file("/sys/class/net/#{b}/bridge/stp_state") do
      its('content') { should match /^0$/ }
    end
  end

  # br42 bridge options tests (nmstate only, AL9+)
  if os.release.to_i >= 9
    describe command('ip -0 -o addr show dev br42') do
      its('stdout') { should match /BROADCAST,MULTICAST,UP,LOWER_UP/ }
    end

    describe command('ip -4 -o addr show dev br42') do
      its('stdout') { should match %r{inet 192.168.42.1/24} }
    end

    # Check to make sure the bridge port is attached correctly
    describe command('bridge link show dev eth10') do
      its('stdout') { should match /master br42/ }
    end

    describe file('/sys/class/net/br42/bridge/stp_state') do
      its('content') { should match /^0$/ }
    end

    describe file('/sys/class/net/br42/bridge/forward_delay') do
      its('content') { should match /^200$/ }
    end
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

  # Boot persistence plumbing. The assertions above are all live kernel state,
  # so without these a converge-time regression -- unit never written, or
  # written but not enabled -- would only surface after someone reboots.
  (1..11).each do |i|
    describe systemd_service("osl-fakenic-eth#{i}.service") do
      it { should be_installed }
      it { should be_enabled }
    end
  end

  # The unit body is load-bearing: a wrong Before=, a missing `-`, or `addr
  # add` instead of `addr replace` only fails at the next boot, long after the
  # suite went green. The path to ip is resolved at converge time and differs
  # by platform, so match on the command rather than pinning it.
  describe file('/etc/systemd/system/osl-fakenic-eth8.service') do
    its('content') { should match(/^Before=network-pre\.target NetworkManager\.service$/) }
    its('content') { should match(%r{^ExecStart=-\S+/ip link add name eth8 type dummy$}) }
    its('content') { should match(%r{^ExecStart=\S+/ip addr replace 192\.168\.1\.100/24 dev eth8$}) }
  end

  # The other half of the boot story, the half osl_ifconfig owns: nmstate
  # writes autoconnect profiles, and NetworkManager recreates even the dummy
  # devices from them.
  if os.release.to_i >= 9
    describe command('nmcli -t -f DEVICE,STATE connection show --active') do
      its('exit_status') { should eq 0 }
      %w(eth1 eth4 eth5 eth9 eth11 eth1.10 eth1.172 br10 br172 br42 br44 bond0).each do |dev|
        its('stdout') { should match(/^#{Regexp.escape(dev)}:activated$/) }
      end
    end

    # nmstate.service renames applied .yml files to .applied, which would
    # fight Chef's ownership of them on every boot. It must stay disabled.
    describe service('nmstate') do
      it { should_not be_enabled }
    end
  end
end
