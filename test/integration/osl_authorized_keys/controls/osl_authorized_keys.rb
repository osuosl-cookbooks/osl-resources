control 'osl_authorized_keys' do
  describe directory('/home/test_user/.ssh') do
    it { should exist }
    its('mode') { should cmp '0700' }
    its('owner') { should cmp 'test_user' }
    its('group') { should cmp 'test_user' }
  end
  describe file('/home/test_user/.ssh/authorized_keys') do
    it { should exist }
    %w(key_1 key_2 key_3).each do |k|
      its('content') { should match /^#{k}$/ }
    end
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
  describe file('/opt/test/.ssh/authorized_keys') do
    it { should exist }
    %w(key_1 key_2 key_3).each do |k|
      its('content') { should match /^#{k}$/ }
    end
    its('mode') { should cmp '0600' }
    its('owner') { should cmp 'test_user' }
    its('group') { should cmp 'root' }
  end
end
