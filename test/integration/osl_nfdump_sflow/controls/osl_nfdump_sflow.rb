control 'osl_nfdump_sflow' do
  describe service 'nfdump-default.service' do
    it { should be_enabled }
    it { should be_running }
  end

  describe port 2055 do
    it { should be_listening }
    its('protocols') { should include 'udp' }
    its('processes') { should cmp 'sfcapd' }
    its('addresses') { should include '0.0.0.0' }
  end

  describe processes('/usr/bin/sfcapd') do
    its('commands') { should include '/usr/bin/sfcapd -D -P /run/sfcapd.default.pid -l /var/cache/nfdump/default -p 2055' }
  end
end
