include_recipe 'osl-selinux'

package 'python3'

directory '/var/www/html' do
  recursive true
end

file '/var/www/html/index.html' do
  content '<html><body>Hello World</body></html>'
end

systemd_unit 'simple-http.service' do
  content({
            Unit: {
              Description: 'Simple HTTP Server for testing',
              After: 'network.target',
            },
            Service: {
              Type: 'simple',
              WorkingDirectory: '/var/www/html',
              ExecStart: '/usr/bin/python3 -m http.server 8080',
              Restart: 'always',
            },
            Install: {
              WantedBy: 'multi-user.target',
            },
          })
  action [:create, :enable, :start]
end

osl_anubis 'default' do
  target 'http://127.0.0.1:8080'
  default_challenge({ 'algorithm' => 'fast', 'difficulty' => 3 })
  # Explicit key, as a load-balanced pair would set it
  ed25519_private_key_hex '4f2b8c1d9e3a7056b4c8d2f1a903e5b7c6d4082f1e9a3b5c7d08f2a4e6b1c3d5'
  extra_env('SLOG_LEVEL' => 'DEBUG')
  custom_bots [
    {
      'name' => 'static-assets',
      'path_regex' => '^/assets/.*$',
      'action' => 'ALLOW',
    },
  ]
  extra_config(
    'store' => {
      'backend' => 'memory',
      'parameters' => {},
    }
  )
end

# Second instance with no key set, to cover the generated-on-first-run path.
# kitchen's enforce_idempotency catches it if the key is regenerated.
osl_anubis 'generated' do
  target 'http://127.0.0.1:8080'
  bind '127.0.0.1:8933'
  metrics_bind ':9091'
  redirect_domains 'anubis-test'
end

# Set up nginx as reverse proxy in front of Anubis for testing
nginx_app 'anubis-test' do
  directive_http [
    'location / {',
    '  proxy_pass http://127.0.0.1:8932;',
    '  proxy_set_header Host $host:$server_port;',
    '  proxy_set_header X-Real-IP $remote_addr;',
    '  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;',
    '}',
  ]
end
