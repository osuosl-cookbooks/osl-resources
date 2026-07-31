control 'osl_chrony_server' do
  describe package 'chrony' do
    it { should be_installed }
  end

  describe file('/etc/chrony.conf') do
    [
      /^pool 2.pool.ntp.org iburst maxsources 4$/,
      /^server time.cloudflare.com iburst nts$/,
      /^server time.nist.gov iburst$/,
      # the kitchen host is not in the ntp_servers map, so every address
      # renders as a peer
      /^peer 192.0.2.10 key 1$/,
      /^peer 2001:db8::10 key 1$/,
      /^peer 192.0.2.11 key 1$/,
      /^peer 2001:db8::11 key 1$/,
      /^peer 198.51.100.10 key 1$/,
      /^peer 2001:db8:1::10 key 1$/,
      %r{^allow 192.0.2.0/24$},
      %r{^allow 2001:db8::/32$},
      %r{^keyfile /etc/chrony.keys$},
      /^local stratum 10 orphan$/,
      %r{^driftfile /var/lib/chrony/drift$},
      /^makestep 1.0 3$/,
      /^rtcsync$/,
      %r{^leapsectz right/UTC$},
      %r{^ntsdumpdir /var/lib/chrony$},
      /^ratelimit interval 1 burst 16$/,
    ].each do |line|
      its('content') { should match(line) }
    end
    its('content') { should_not match(/^port 0$/) }
    its('content') { should_not match(/^cmdport 0$/) }
    its('content') { should_not match(/^allow all$/) }
    its('content') { should_not match(/^ntsservercert/) }
  end

  describe file('/etc/chrony.keys') do
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'chrony' }
    its('mode') { should cmp '0640' }
    its('content') { should match(/^1 SHA256 HEX:[0-9a-f]{40}$/) }
  end

  describe service 'chronyd' do
    it { should be_running }
    it { should be_enabled }
  end

  describe service 'systemd-timesyncd' do
    it { should_not be_running }
    it { should_not be_enabled }
  end

  describe port(123) do
    it { should be_listening }
    its('protocols') { should include 'udp' }
  end

  describe port(4460) do
    it { should_not be_listening }
  end
end
