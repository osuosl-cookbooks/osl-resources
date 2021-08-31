(1..6).each do |i|
  osl_fakenic "eth#{i}"
end

osl_fakenic 'eth7' do
  ip4 '192.168.0.100/24'
end

osl_fakenic 'eth8' do
  ip6 'fe80::6/64'
end

osl_fakenic 'eth9' do
  ip4 '192.168.1.100/24'
  ip6 'fe80::7/64'
  mac_address '00:1a:4b:a6:a7:c4'
  multicast true
end

file '/etc/sysconfig/network-scripts/ifcfg-eth5' do
  content <<-EOF
DEVICE=eth5
BOOTPROTO=static
IPADDR=10.1.1.20
NETMASK=255.255.255.0
NM_CONTROLLED=no
TYPE=dummy
  EOF
end

osl_ifconfig 'eth1' do
  target ''
  bootproto 'none'
  nm_controlled 'no'
  device 'eth1'
  type 'dummy'
end

osl_ifconfig 'eth1vlan172' do
  target ''
  device 'eth1.172'
  onboot 'yes'
  bootproto 'none'
  nm_controlled 'no'
  userctl 'no'
  vlan 'yes'
  bridge 'br172'
end

osl_ifconfig 'eth1vlan10' do
  target ''
  device 'eth1.10'
  onboot 'yes'
  bootproto 'none'
  nm_controlled 'no'
  userctl 'no'
  bridge 'br10'
  vlan 'yes'
end

osl_ifconfig 'br172' do
  target ''
  device 'br172'
  onboot 'yes'
  bootproto 'none'
  nm_controlled 'no'
  delay '0'
end

osl_ifconfig 'br10' do
  target '172.16.18.1'
  mask '255.255.255.0'
  network '172.16.18.0'
  device 'br10'
  onboot 'yes'
  bootproto 'static'
  nm_controlled 'no'
  delay '0'
end

# bonding interfaces
osl_ifconfig 'eth2' do
  device 'eth2'
  onboot 'yes'
  bootproto 'none'
  master 'bond0'
  slave 'yes'
  type 'dummy'
end

osl_ifconfig 'eth3' do
  device 'eth3'
  onboot 'yes'
  bootproto 'none'
  master 'bond0'
  slave 'yes'
  type 'dummy'
end

osl_ifconfig 'bond0' do
  target '172.16.20.10'
  mask '255.255.255.0'
  network '172.16.20.0'
  device 'bond0'
  bootproto 'static'
  bonding_opts 'mode=4 miimon=100 lacp_rate=0'
  onboot 'yes'
end

osl_ifconfig 'eth4' do
  device 'eth4'
  target '172.16.50.10'
  mask '255.255.255.0'
  network '172.16.50.0'
  bootproto 'static'
  onboot 'yes'
  ipv6init 'yes'
  ipv6addr 'fe80::2/64'
  ipv6_defaultgw 'fe80::1/64'
  type 'dummy'
end

osl_ifconfig 'eth5' do
  device 'eth5'
  type 'dummy'
  action :enable
end

osl_ifconfig 'eth6' do
  device 'eth6'
  target %w(
    10.1.30.20
    10.1.30.21
  )
  onboot 'yes'
  ipv6init 'yes'
  ipv6addr 'fe80::3/64'
  ipv6addrsec %w(
    fe80::4/64
    fe80::5/64
  )
  ipv6_defaultgw 'fe80::1/64'
  nm_controlled 'yes'
  type 'dummy'
end
