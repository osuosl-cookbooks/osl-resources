control 'osl_authorized_keys_remove' do
  describe directory('/home/test_user_1/.ssh') do
    it { should exist }
  end
  describe file('/home/test_user_1/.ssh/authorized_keys') do
    it { should exist }
    %w(key_1 key_3).each do |k|
      its('content') { should match /^#{k}$/ }
    end
    its('mode') { should cmp '0600' }
    its('owner') { should cmp 'test_user_1' }
    its('group') { should cmp 'test_user_1' }
  end

  describe directory('/home/test_user_2/.ssh') do
    it { should exist }
    its('mode') { should cmp '0700' }
    its('owner') { should cmp 'test_user_2' }
    its('group') { should cmp 'test_user_2' }
  end
  describe file('/home/test_user_2/authorized_keys') do
    it { should_not exist }
  end
  describe file('/home/test_user_2/.ssh/id_rsa') do
    it { should exist }
    its('content') { should cmp 'test_key' }
    its('mode') { should cmp '0600' }
    its('owner') { should cmp 'test_user_2' }
    its('group') { should cmp 'test_user_2' }
  end
end
