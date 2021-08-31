control 'osl_fakenic' do
  describe command('ip -details link show dev dummy1') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /UP/ }
    its('stdout') { should match /^\s+dummy\s/ }
  end

  describe command('ip -details link show dev dummy2') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /UP/ }
    its('stdout') { should match /^\s+dummy\s/ }
    its('stdout') { should match /^\s+dummy\s/ }
  end
  describe command('ip addr show dev dummy2') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match %r{^\s+link/ether 00:1a:4b:a6:a7:c4} }
    its('stdout') { should match %r{^\s+inet 192.168.0.1/24 scope global dummy2} }
    its('stdout') { should match %r{^\s+inet6 fe80::1/64 scope link} }
  end
end
