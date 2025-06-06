control 'osl_caddy' do
  describe package 'caddy' do
    it { should be_installed }
  end

  describe directory '/etc/caddy/sites' do
    it { should exist }
  end

  describe file '/etc/caddy/Caddyfile' do
    its('owner') { should cmp 'root' }
    its('group') { should cmp 'root' }
    its('content') do
      should cmp <<~EOF
        # This file was generated by Chef Infra
        # Do NOT modify this file by hand.
        {
          acme_ca https://127.0.0.1:14000/dir
          acme_ca_root /opt/pebble/test/certs/pebble.minica.pem
          ocsp_stapling off
        }

        import /etc/caddy/sites/*
      EOF
    end
  end

  describe file '/etc/caddy/sites/simple.example.org.caddyfile' do
    its('content') do
      should cmp <<~EOF
        # This file was generated by Chef Infra
        # Do NOT modify this file by hand.
        simple.example.org {
          log
          respond "Hello from a simple site!"
        }
      EOF
    end
  end

  describe file '/etc/caddy/sites/hash.example.org.caddyfile' do
    its('content') do
      should cmp <<~EOF
        # This file was generated by Chef Infra
        # Do NOT modify this file by hand.
        hash.example.org {
          log
          root * /var/www/hash.example.org
          file_server
          header +X-Content-Type-Options nosniff
          header -Server
          header X-Frame-Options SAMEORIGIN
          header {"Strict-Transport-Security"=>"max-age=31536000; includeSubDomains; preload"}
          header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          tls {
            protocols tls1.2 tls1.3
            ciphers TLS_AES_128_GCM_SHA256
            ciphers TLS_CHACHA20_POLY1305_SHA256
            curves x25519
          }
          route /special/* {
            respond "This is a special route" 200
            # Route-specific comment
          }
          # This is a raw comment block, processed as-is
          # Example of a route with specific ordering and handlers
          route /assets/* {
            header Cache-Control "public, max-age=3600"
            try_files {path} /index.html
            file_server {
              hide .git .DS_Store
            }
          }
        #{'  '}
          # Another snippet demonstrating a handle_errors block
          handle_errors {
            rewrite * /error.html
            file_server
          }
        }
      EOF
    end
  end

  describe service 'caddy' do
    it { should be_enabled }
    it { should be_running }
  end

  %w(80 443).each do |p|
    describe port p do
      it { should be_listening }
      its('processes') { should include 'caddy' }
    end
  end

  %w(simple.example.org hash.example.org).each do |s|
    describe http('localhost', headers: { 'Host' => s }) do
      its('status') { should cmp 308 }
      its('headers.location') { should cmp "https://#{s}/" }
    end

    describe command "curl --resolve '#{s}:443:127.0.0.1' https://#{s} -kv" do
      its('stderr') { should match /issuer: CN=Pebble Intermediate CA/ }
      its('stderr') { should match /subject: CN=#{s}/ }
      case s
      when 'simple.example.org'
        its('stdout') { should match /Hello from a simple site!/ }
      when 'hash.example.org'
        its('stdout') { should match /Hello hash world!/ }
      end
    end
  end
end
