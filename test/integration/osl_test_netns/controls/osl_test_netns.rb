control 'osl_test_netns' do
  describe command('ip netns list') do
    its('stdout') { should match(/^testclient(\s|$)/) }
    its('stdout') { should match(/^second(\s|$)/) }
  end

  describe command('ip -details link show veth-srv') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/state UP/) }
    its('stdout') { should match(/^\s+veth\s/) }
  end

  describe command('ip addr show veth-srv') do
    its('stdout') { should match(%r{inet 140\.211\.166\.158/28}) }
  end

  describe command('ip -n testclient -details link show veth-cli') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/state UP/) }
    its('stdout') { should match(/^\s+veth\s/) }
    its('stdout') { should match(%r{link/ether 00:1a:4b:a6:a7:c4}) }
  end

  describe command('ip -n testclient addr show veth-cli') do
    its('stdout') { should match(%r{inet 140\.211\.166\.157/28}) }
  end

  describe command('ip -n testclient -o link show lo') do
    its('stdout') { should match(/state (UP|UNKNOWN)/) }
  end

  # End-to-end bidirectional packet delivery: from inside the netns, ping
  # the server-side IP. This is the load-bearing assertion — if this fails,
  # the resource is broken regardless of what the show commands report.
  describe command('ip netns exec testclient ping -c1 -W2 140.211.166.158') do
    its('exit_status') { should eq 0 }
  end

  # Default-named second pair should also work end-to-end.
  describe command('ip -details link show veth-srv-second') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/state UP/) }
    its('stdout') { should match(/^\s+veth\s/) }
  end

  describe command('ip netns exec second ping -c1 -W2 192.0.2.1') do
    its('exit_status') { should eq 0 }
  end
end
