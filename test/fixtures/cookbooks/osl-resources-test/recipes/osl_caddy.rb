include_recipe 'osl-acme::server'

directory '/var/www/hash.example.org' do
  recursive true
end

file '/var/www/hash.example.org/index.html' do
  content 'Hello hash world!'
end

osl_caddy 'default'

osl_caddy_site 'simple.example.org' do
  content <<~EOF
    simple.example.org {
      log
      respond "Hello from a simple site!"
    }
  EOF
  notifies :reload, 'osl_caddy[default]'
end

osl_caddy_site 'hash.example.org' do
  content(
    'hash.example.org' => {
      'log' => true,
      'root' => '* /var/www/hash.example.org',
      'file_server' => true,
      'header' => [
        '+X-Content-Type-Options nosniff',
        '-Server',
        'X-Frame-Options SAMEORIGIN',
        { 'Strict-Transport-Security' => 'max-age=31536000; includeSubDomains; preload' },
        'Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"',
      ],
      'tls' => {
        'protocols' => 'tls1.2 tls1.3',
        'ciphers' => %w(
          TLS_AES_128_GCM_SHA256
          TLS_CHACHA20_POLY1305_SHA256
        ),
        'curves' => 'x25519',
      },
      'route /special/*' => {
        'respond' => '"This is a special route" 200',
        '# Route-specific comment' => nil,
      },
      'raw_lines' => [
      '# This is a raw comment block, processed as-is',
      '# Example of a route with specific ordering and handlers',
      'route /assets/* {',
      '  header Cache-Control "public, max-age=3600"',
      '  try_files {path} /index.html',
      '  file_server {',
      '    hide .git .DS_Store',
      '  }',
      '}',
      '',
      '# Another snippet demonstrating a handle_errors block',
      'handle_errors {',
      '  rewrite * /error.html',
      '  file_server',
      '}',
      ],
    }
  )
  notifies :reload, 'osl_caddy[default]'
end
