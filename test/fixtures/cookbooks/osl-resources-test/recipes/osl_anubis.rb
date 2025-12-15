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
