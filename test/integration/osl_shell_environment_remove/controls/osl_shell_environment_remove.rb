control 'osl_shell_environment_remove' do
  describe file('/etc/profile.d/EDITOR.sh') do
    it { should exist }
    its('content') { should match /^export EDITOR="vim"/ }
  end

  describe file('/etc/profile.d/LESSER_EDITOR.sh') do
    it { should_not exist }
  end
end
