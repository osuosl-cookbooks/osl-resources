# osl_fakenic persists by default, so the dummies come back after a reboot.
# Without that a manual reboot leaves this suite with no interfaces at all and
# verify fails for reasons unrelated to osl_ifconfig. The units recreate only
# the device -- everything on top comes back from the NetworkManager profiles
# nmstatectl wrote.
(1..5).each do |i|
  osl_fakenic "eth#{i}"
end

osl_fakenic 'eth6' do
  ip4 '192.168.0.100/24'
end

osl_fakenic 'eth7' do
  ip6 '2001:db8::6/64'
end

osl_fakenic 'eth8' do
  ip4 '192.168.1.100/24'
  ip6 '2001:db8::7/64'
  mac_address '00:1a:4b:a6:a7:c4'
  multicast true
end

# eth10 has no osl_ifconfig resource of its own -- it is br42's port, and the
# fixture's only coverage of an unmanaged bridge port. Its unit is what brings
# it back; do not "fix" this by adding an osl_ifconfig 'eth10'.
%w(eth9 eth10 eth11).each do |i|
  osl_fakenic i
end

osl_ifconfig 'eth1' do
  bootproto 'none'
  nm_controlled 'no'
  type 'dummy'
end

osl_ifconfig 'eth1.10' do
  onboot 'yes'
  bootproto 'none'
  nm_controlled 'no'
  userctl 'no'
  bridge 'br10'
  vlan 'yes'
end

osl_ifconfig 'eth1.172' do
  onboot 'yes'
  bootproto 'none'
  nm_controlled 'no'
  userctl 'no'
  vlan 'yes'
  bridge 'br172'
end

osl_ifconfig 'br172' do
  type 'linux-bridge'
  bridge_ports %w(eth1.172)
  onboot 'yes'
  bootproto 'none'
  nm_controlled 'no'
  delay '0'
end

osl_ifconfig 'br10' do
  type 'linux-bridge'
  bridge_ports %w(eth1.10)
  ipv4addr '172.16.18.1'
  mask '255.255.255.0'
  network '172.16.18.0'
  onboot 'yes'
  bootproto 'static'
  nm_controlled 'no'
  delay '0'
end

osl_ifconfig 'br42' do
  type 'linux-bridge'
  bridge_ports %w(eth10)
  bridge_options(
    stp: { enabled: false, 'forward-delay': 2 }
  )
  ipv4addr '192.168.42.1'
  mask '255.255.255.0'
  onboot 'yes'
  bootproto 'static'
  nm_controlled 'no'
  delay '0'
end

# Member-side membership only: the bridge does not list the port. That is
# BRIDGE= on ifcfg and controller: on nmstate, previously dropped on EL9+.
osl_ifconfig 'br44' do
  type 'linux-bridge'
  onboot 'yes'
  bootproto 'none'
  nm_controlled 'no'
  delay '0'
end

osl_ifconfig 'eth11' do
  onboot 'yes'
  bootproto 'none'
  nm_controlled 'no'
  bridge 'br44'
  type 'dummy'
end

# bonding interfaces
osl_ifconfig 'bond0' do
  ipv4addr '172.16.20.10'
  mask '255.255.255.0'
  network '172.16.20.0'
  bootproto 'static'
  # By name rather than mode=0: identical semantics, and the only end-to-end
  # cover for non-numeric bonding values.
  bonding_opts 'mode=balance-rr miimon=100'
  bond_ports %w(eth2 eth3)
  onboot 'yes'
end

osl_ifconfig 'eth2' do
  onboot 'yes'
  bootproto 'none'
  master 'bond0'
  slave 'yes'
  type 'dummy'
  notifies :enable, 'osl_ifconfig[bond0]', :immediately
end

osl_ifconfig 'eth3' do
  onboot 'yes'
  bootproto 'none'
  master 'bond0'
  slave 'yes'
  type 'dummy'
  notifies :enable, 'osl_ifconfig[bond0]', :immediately
end

osl_ifconfig 'eth4' do
  ipv4addr '172.16.50.10'
  mask '255.255.255.0'
  network '172.16.50.0'
  bootproto 'static'
  onboot 'yes'
  ipv6init 'yes'
  ipv6addr '2001:db8::2/64'
  ipv6_defaultgw '2001:db8::1/64'
  type 'dummy'
end

osl_ifconfig 'eth5' do
  ipv4addr %w(
    10.1.30.20
    10.1.30.21
  )
  mask %w(
    255.255.255.0
    255.255.255.0
  )
  onboot 'yes'
  ipv6init 'yes'
  ipv6addr '2001:db8::3/64'
  ipv6addrsec %w(
    2001:db8::4/64
    2001:db8::5/64
  )
  ipv6_defaultgw '2001:db8::1/64'
  nm_controlled 'yes'
  type 'dummy'
end

# Its own subnet so a wrong prefix cannot hide behind eth4's route, plus the
# only mtu/hwaddr coverage.
osl_ifconfig 'eth9' do
  onboot 'yes'
  bootproto 'static'
  ipv4addr '172.16.51.11'
  mask '255.255.255.0'
  mtu '1400'
  # nmstate mac-address: sets the MAC; ifcfg HWADDR= matches, and ifup refuses
  # a dummy whose random MAC differs.
  hwaddr '00:1a:4b:a6:a7:c9' if node['platform_version'].to_i >= 9
  ipv6init 'yes'
  ipv6_autoconf 'no'
  nm_controlled 'yes'
  type 'dummy'
end
