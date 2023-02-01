package 'bind-utils'

osl_dnsdist 'default' do
  servers(
    '8.8.8.8' => {
      'qps' => 1000,
    }
  )
end

osl_dnsdist 'caching' do
  listen_addresses %w(127.0.0.1:5300)
  acls %w(127.0.0.1/8)
  servers(
    '140.211.166.130' => { 'pool' => 'caching', 'qps' => 1000 },
    '140.211.166.131' => { 'pool' => 'caching', 'qps' => 100 }
  )
  console_address '127.0.0.1:5198'
  console_key 'Au2XFtASDf0BQNek54sAxWKGMiJsnrHvB6PvFICadcA='
  netmask_groups('osl_only' => %w(127.0.0.1/8 140.211.15.0/24))
  webserver_address '0.0.0.0:8084'
  webserver_acl %w(0.0.0.0/0)
  webserver_password 'password'
  extra_options [
    "addAction(NetmaskGroupRule(osl_only), PoolAction('caching'))",
  ]
end

osl_dnsdist 'auth' do
  listen_addresses %w(127.0.0.1:5301)
  acls %w(0.0.0.0/0 ::/0)
  servers(
    '140.211.166.140' => { 'pool' => 'auth', 'qps' => 1000 },
    '140.211.166.141' => { 'pool' => 'auth', 'qps' => 100 }
  )
  console_address '127.0.0.1:5197'
  console_key 'Au2XFtASDf0BQNek54sAxWKGMiJsnrHvB6PvFICadcA='
  webserver_password 'password'
  extra_options [
    "addAction(AllRule(), PoolAction('auth'))",
  ]
end
