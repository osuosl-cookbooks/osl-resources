control 'osl_ssh_key' do
  describe directory('/home/test_user/.ssh') do
    it { should exist }
    its('mode') { should cmp '0700' }
    its('owner') { should cmp 'test_user' }
    its('group') { should cmp 'test_user' }
  end
  describe file('/home/test_user/.ssh/id_rsa') do
    it { should exist }
    its('content') { should cmp 'test_key' }
    its('mode') { should cmp '0600' }
    its('owner') { should cmp 'test_user' }
    its('group') { should cmp 'test_user' }
  end
  describe file('/home/test_user/.ssh/id_rsa.pub') do
    it { should exist }
    its('content') { should cmp 'test_key_pub' }
    its('mode') { should cmp '0600' }
    its('owner') { should cmp 'test_user' }
    its('group') { should cmp 'test_user' }
  end

  describe directory('/opt/test/.ssh') do
    it { should exist }
    its('mode') { should cmp '0700' }
    its('owner') { should cmp 'test_user' }
    its('group') { should cmp 'root' }
  end
  describe file('/opt/test/.ssh/id_ed25519') do
    it { should exist }
    its('mode') { should cmp '0600' }
    its('content') { should cmp 'curvy_key' }
    its('owner') { should cmp 'test_user' }
    its('group') { should cmp 'root' }
  end
end
