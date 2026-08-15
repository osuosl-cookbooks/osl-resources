control 'osl_fakenic_delete' do
  describe command('ip -details link show dev dummy1') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /UP/ }
    its('stdout') { should match /^\s+dummy\s/ }
  end

  describe command('ip -details link show dev dummy2') do
    its('exit_status') { should eq 1 }
  end

  # dummy1 is still persisted.
  describe systemd_service('osl-fakenic-dummy1.service') do
    it { should be_installed }
    it { should be_enabled }
  end

  # :delete must take the unit with it, or the next reboot resurrects an
  # interface that was deliberately removed.
  describe file('/etc/systemd/system/osl-fakenic-dummy2.service') do
    it { should_not exist }
  end
end
