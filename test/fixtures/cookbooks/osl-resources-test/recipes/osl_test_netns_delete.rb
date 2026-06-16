osl_test_netns 'keepme' do
  server_interface 'veth-srv-keep'
  server_ip        '192.0.2.5/30'
  client_interface 'veth-cli-keep'
  client_ip        '192.0.2.6/30'
end

osl_test_netns 'gone' do
  server_interface 'veth-srv-gone'
  server_ip        '192.0.2.9/30'
  client_interface 'veth-cli-gone'
  client_ip        '192.0.2.10/30'
  client_mac       '00:1a:4b:a6:a7:c5'
  action [:create, :delete]
end

# Deleting a netns that was never created must be a no-op.
osl_test_netns 'never-existed' do
  action :delete
end
