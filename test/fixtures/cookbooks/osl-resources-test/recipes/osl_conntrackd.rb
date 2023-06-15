osl_conntrackd node['ipaddress'] do
  interface node['network']['default_interface']
  ipv4_destination_address '127.0.0.1'
  address_ignore [
    '127.0.0.1',
    node['ipaddress'],
  ]
end
