osl_fakenic 'eth1'
osl_fakenic 'eth2'
osl_fakenic 'eth3'

osl_ifconfig 'eth1' do
  ipv4addr '10.30.0.1'
  mask '255.255.255.0'
  type 'dummy'
end

osl_ifconfig 'eth2' do
  ipv4addr '10.40.0.1'
  mask '255.255.255.0'
  type 'dummy'
end

osl_route 'eth1' do
  routes [
    {
      address: '10.50.0.0',
      netmask: '255.255.254.0',
      gateway: '10.30.0.1',
    },
  ]
end

osl_route 'eth2' do
  routes [
    {
      address: '10.60.0.0',
      netmask: '255.255.254.0',
    },
    {
      address: '10.70.0.0',
      netmask: '255.255.254.0',
      gateway: '10.40.0.1',
    },
  ]
end

osl_route 'eth3' do
  routes [
    {
      address: '10.80.0.0',
      netmask: '255.255.254.0',
      gateway: '10.40.0.1',
    },
  ]
  action :remove
end
