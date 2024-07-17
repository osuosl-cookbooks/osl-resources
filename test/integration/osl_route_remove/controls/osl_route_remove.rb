os_rel = os.release.to_i

control 'osl_route_remove' do
  describe file('/etc/sysconfig/network-scripts/route-eth1') do
    it { should_not exist }
  end if os_rel < 9

  describe command('ip -o addr show eth1') do
    its('stdout') { should match /eth1.*inet/ }
  end

  describe command 'ip r' do
    its('stdout') { should_not match /^10.50.0.0/ }
  end if os_rel >= 9
end
