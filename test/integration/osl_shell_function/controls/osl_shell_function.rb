control 'osl_shell_function' do
  describe file('/etc/profile.d/hello.sh') do
    it { should exist }
    its('content') { should match /^hello\(\) \{/ }
    its('content') { should match /echo "Hello, \$@"/ }
  end

  describe file('/etc/profile.d/pcp_test.sh') do
    it { should exist }
    its('content') { should match /^pcp_test\(\) \{/ }
    its('content') { should match %r{/usr/bin/pcp_node_info -h localhost -p 9898 -U pgpool -w "\$@"} }
  end

  # Test that the function actually works and passes arguments
  describe command('bash -lc "hello world"') do
    its('stdout') { should match /Hello, world/ }
    its('exit_status') { should eq 0 }
  end
end
