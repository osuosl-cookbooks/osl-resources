control 'osl_shell_alias_remove' do
  describe file('/etc/profile.d/ll.sh') do
    it { should exist }
    its('content') { should match /^alias ll="ls -al"/ }
  end

  describe file('/etc/profile.d/sl.sh') do
    it { should_not exist }
  end
end
