osl_fakenic 'eth1'
osl_fakenic 'eth2'
osl_fakenic 'eth3'

osl_ifconfig '10.30.0.1' do
  mask '255.255.255.0'
  device 'eth1'
  type 'dummy'
end

osl_ifconfig '10.40.0.1' do
  mask '255.255.255.0'
  device 'eth2'
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
  action :remove
end
