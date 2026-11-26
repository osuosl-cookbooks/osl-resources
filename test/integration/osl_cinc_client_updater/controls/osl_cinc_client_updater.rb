control 'osl_cinc_client_updater' do
  describe command '/opt/cinc/bin/cinc-client --version' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /^Cinc Client: 19\.\d+\.\d+/ }
  end
  describe file '/opt/cinc.upgrade' do
    it { should_not exist }
  end
  # The newest iteration is installed, not just the newest version
  describe command 'rpm -q cinc --qf "%{RELEASE}"' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /^\d+/ }
  end if os.redhat?
  describe command '/opt/cinc/embedded/bin/gem list mixlib-install' do
    its('stdout') { should match /mixlib-install \(.*4\.\d+\.\d+/ }
  end
end
