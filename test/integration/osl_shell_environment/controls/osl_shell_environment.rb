control 'osl_shell_environment' do
  describe file('/etc/profile.d/EDITOR.sh') do
    it { should exist }
    its('content') { should match /^export EDITOR="vim"/ }
  end
end
