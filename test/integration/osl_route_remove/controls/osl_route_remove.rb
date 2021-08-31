control 'osl_route_remove' do
  describe file('/etc/sysconfig/network-scripts/route-eth1') do
    it { should_not exist }
  end

  describe command('ip -o addr show eth1') do
    its('stdout') { should match /eth1.*inet/ }
  end
end
