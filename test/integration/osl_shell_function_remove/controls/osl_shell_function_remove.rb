control 'osl_shell_function_remove' do
  describe file('/etc/profile.d/hello.sh') do
    it { should exist }
    its('content') { should match /^hello\(\) \{/ }
  end

  describe file('/etc/profile.d/goodbye.sh') do
    it { should_not exist }
  end
end
