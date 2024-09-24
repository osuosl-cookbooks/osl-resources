control 'osl_nfdump' do
  describe service 'nfdump-default.service' do
    it { should be_enabled }
    it { should be_running }
  end

  describe port 2055 do
    it { should be_listening }
    its('protocols') { should include 'udp' }
    its('processes') { should cmp 'nfcapd' }
    its('addresses') { should include '0.0.0.0' }
  end

  describe processes('/usr/bin/nfcapd') do
    its('commands') { should include '/usr/bin/nfcapd -D -P /run/nfcapd.default.pid -l /var/cache/nfdump/default -p 2055' }
  end
end
