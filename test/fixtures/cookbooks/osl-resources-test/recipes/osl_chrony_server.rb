# The kitchen host is not in the ntp_servers map, so every address renders as
# a peer. The key is a throwaway test value.
osl_chrony_server 'default' do
  ntp_servers(
    'ns1' => %w(192.0.2.10 2001:db8::10),
    'ns2' => %w(192.0.2.11 2001:db8::11),
    'ns3' => %w(198.51.100.10 2001:db8:1::10)
  )
  allowed_networks %w(192.0.2.0/24 2001:db8::/32)
  key '746573746b6579746573746b6579746573746b65'
end
