control 'osl_anubis' do
  describe package 'anubis' do
    it { should be_installed }
  end

  describe directory '/run/anubis' do
    its('mode') { should cmp '0755' }
    its('owner') { should cmp 'anubis' }
    its('group') { should cmp 'anubis' }
  end

  describe file '/etc/anubis/default.env' do
    its('content') do
      should cmp <<~EOF
        # This file was generated by Chef Infra
        # Do NOT modify this file by hand.
        BIND=/run/anubis/default.sock
        DIFFICULTY=4
        METRICS_BIND=:9090
        SERVE_ROBOTS_TXT=false
        BIND_NETWORK=unix
        COOKIE_EXPIRATION_TIME=168h
        COOKIE_PARTITIONED=false
      EOF
    end
  end

  describe service 'anubis@default.service' do
    it { should be_enabled }
    it { should be_running }
  end

  describe file '/run/anubis/default.sock' do
    its('mode') { should cmp '0770' }
    its('type') { should cmp 'socket' }
    its('owner') { should cmp 'anubis' }
    its('group') { should cmp 'anubis' }
  end
end
