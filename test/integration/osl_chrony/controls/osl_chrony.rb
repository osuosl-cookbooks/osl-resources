chrony_conf = os.family == 'redhat' ? '/etc/chrony.conf' : '/etc/chrony/chrony.conf'
drift_file = os.family == 'redhat' ? '/var/lib/chrony/drift' : '/var/lib/chrony/chrony.drift'

control 'osl_chrony' do
  describe package 'chrony' do
    it { should be_installed }
  end

  describe file(chrony_conf) do
    [
      /^pool time.osuosl.org iburst maxsources 3$/,
      /^pool 2.pool.ntp.org iburst maxsources 2$/,
      /^driftfile #{drift_file}$/,
      /^makestep 1.0 3$/,
      /^rtcsync$/,
      %r{^logdir /var/log/chrony$},
      /^port 0$/,
      /^cmdport 0$/,
    ].each do |line|
      its('content') { should match(line) }
    end
  end

  describe service 'chronyd' do
    it { should be_running }
    it { should be_enabled }
  end

  describe service 'systemd-timesyncd' do
    it { should_not be_running }
    it { should_not be_enabled }
  end
end
