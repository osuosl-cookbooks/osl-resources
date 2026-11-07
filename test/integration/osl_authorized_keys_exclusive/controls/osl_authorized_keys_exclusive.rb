control 'osl_authorized_keys_exclusive' do
  describe directory('/home/test_user/.ssh') do
    it { should exist }
    its('mode') { should cmp '0700' }
    its('owner') { should cmp 'test_user' }
    its('group') { should cmp 'test_user' }
  end

  describe file('/home/test_user/.ssh/authorized_keys') do
    it { should exist }
    its('content') { should eq "key_1\nkey_2\n" }
    its('content') { should_not match /^stray_key$/ }
    its('mode') { should cmp '0600' }
    its('owner') { should cmp 'test_user' }
    its('group') { should cmp 'test_user' }
  end
end
