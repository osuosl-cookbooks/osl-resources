control 'osl_test_netns_delete' do
  describe command('ip netns list') do
    its('stdout') { should match(/^keepme(\s|$)/) }
    its('stdout') { should_not match(/^gone(\s|$)/) }
    its('stdout') { should_not match(/^never-existed(\s|$)/) }
  end

  # The kept netns is still wired up end-to-end.
  describe command('ip -details link show veth-srv-keep') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/state UP/) }
    its('stdout') { should match(/^\s+veth\s/) }
  end

  describe command('ip netns exec keepme ping -c1 -W2 192.0.2.5') do
    its('exit_status') { should eq 0 }
  end

  # The torn-down netns leaves nothing behind.
  describe command('ip link show veth-srv-gone') do
    its('exit_status') { should_not eq 0 }
  end

  describe command('ip link show veth-cli-gone') do
    its('exit_status') { should_not eq 0 }
  end
end
