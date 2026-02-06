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

osl_fakenic 'eth9'

osl_fakenic 'eth10'

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

# bonding interfaces
osl_ifconfig 'bond0' do
  ipv4addr '172.16.20.10'
  mask '255.255.255.0'
  network '172.16.20.0'
  bootproto 'static'
  bonding_opts 'mode=0 miimon=100'
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

osl_ifconfig 'eth9' do
  onboot 'yes'
  bootproto 'static'
  ipv4addr '172.16.50.11'
  ipv6init 'yes'
  ipv6_autoconf 'no'
  nm_controlled 'yes'
  type 'dummy'
end
