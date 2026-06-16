osl_test_netns 'testclient' do
  server_interface 'veth-srv'
  server_ip        '140.211.166.158/28'
  client_interface 'veth-cli'
  client_ip        '140.211.166.157/28'
  client_mac       '00:1a:4b:a6:a7:c4'
end

# Second netns with default-derived interface names, so two test netns can
# coexist on the same host.
osl_test_netns 'second' do
  server_ip '192.0.2.1/30'
  client_ip '192.0.2.2/30'
end
