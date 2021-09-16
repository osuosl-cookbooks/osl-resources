control 'osl_ssh_key_remove' do
  describe directory('/home/test_user_1/.ssh') do
    it { should exist }
    its('mode') { should cmp '0700' }
    its('owner') { should cmp 'test_user_1' }
    its('group') { should cmp 'test_user_1' }
  end
  describe file('/home/test_user_1/.ssh/id_rsa') do
    it { should_not exist }
  end
  describe file('/home/test_user_1/.ssh/id_ed25519') do
    it { should exist }
    its('content') { should cmp 'test_key' }
    its('mode') { should cmp '0600' }
    its('owner') { should cmp 'test_user_1' }
    its('group') { should cmp 'test_user_1' }
  end

  describe directory('/home/test_user_2/') do
    it { should exist }
  end
  describe directory('/home/test_user_2/.ssh') do
    it { should_not exist }
  end
end
