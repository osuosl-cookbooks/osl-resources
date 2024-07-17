osl_fakenic 'eth1'

osl_ifconfig 'eth1' do
  ipv4addr '10.30.0.1'
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
  action [:add, :remove]
end
