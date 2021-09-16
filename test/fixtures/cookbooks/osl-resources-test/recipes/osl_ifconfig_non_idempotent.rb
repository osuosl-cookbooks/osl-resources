(1..3).each do |i|
  osl_fakenic "eth#{i}"
end

file '/etc/sysconfig/network-scripts/ifcfg-eth1' do
  content <<~EOF
    DEVICE=eth1
    BOOTPROTO=static
    IPADDR=10.1.30.20
    NETMASK=255.255.255.0
    NM_CONTROLLED=no
    TYPE=dummy
  EOF
end

execute 'ifup eth1'

osl_ifconfig 'eth1' do
  device 'eth1'
  type 'dummy'
  action :disable
end

osl_ifconfig 'eth2' do
  device 'eth2'
  nm_controlled 'no'
  type 'dummy'
  target '10.1.30.20'
  action [:add, :delete]
end

file '/etc/sysconfig/network-scripts/ifcfg-eth3' do
  content <<~EOF
    DEVICE=eth3
    BOOTPROTO=static
    IPADDR=10.1.1.20
    NETMASK=255.255.255.0
    NM_CONTROLLED=no
    TYPE=dummy
  EOF
end

osl_ifconfig 'eth3' do
  device 'eth3'
  type 'dummy'
  force true
  action :enable
end
