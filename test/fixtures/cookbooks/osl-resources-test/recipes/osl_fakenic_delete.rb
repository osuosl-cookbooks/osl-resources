osl_fakenic 'dummy1'

osl_fakenic 'dummy2' do
  ip4 '192.168.0.1/24'
  ip6 'fe80::1/64'
  mac_address '00:1a:4b:a6:a7:c4'
  multicast true
  action [:create, :delete]
end

osl_fakenic 'lo' do
  action :delete
end
