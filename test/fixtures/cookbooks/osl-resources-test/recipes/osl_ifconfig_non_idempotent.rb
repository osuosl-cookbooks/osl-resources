(1..3).each do |i|
  osl_fakenic "eth#{i}"
end

osl_ifconfig 'eth1' do
  device 'eth1'
  bootproto 'static'
  ipv4addr '10.1.30.20'
  mask '255.255.255.0'
  type 'dummy'
  action :add
end

osl_ifconfig 'eth1-disable' do
  device 'eth1'
  bootproto 'static'
  ipv4addr '10.1.30.20'
  mask '255.255.255.0'
  type 'dummy'
  action :disable
end

osl_ifconfig 'eth2' do
  device 'eth2'
  nm_controlled 'no'
  type 'dummy'
  ipv4addr '10.1.30.20'
  action :add
end

osl_ifconfig 'eth2-delete' do
  device 'eth2'
  nm_controlled 'no'
  type 'dummy'
  ipv4addr '10.1.30.20'
  action :delete
end

osl_ifconfig 'eth3' do
  device 'eth3'
  bootproto 'static'
  ipv4addr '10.1.1.20'
  mask '255.255.255.0'
  type 'dummy'
  force true
  action :add
end

osl_ifconfig 'eth3-enable' do
  device 'eth3'
  bootproto 'static'
  ipv4addr '10.1.1.20'
  mask '255.255.255.0'
  type 'dummy'
  force true
  action :enable
end
