control 'osl_shell_alias' do
  describe file('/etc/profile.d/ll.sh') do
    it { should exist }
    its('content') { should match /^alias ll="ls -al"/ }
  end
end
