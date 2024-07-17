os_rel = os.release.to_i

control 'osl_ifconfig_non_idempotent' do
  if os_rel >= 9
    describe interface 'eth1' do
      it { should_not exist }
    end

    describe interface 'eth2' do
      it { should_not exist }
    end

    describe interface 'eth3' do
      it { should exist }
    end
  else
    %w(eth1 eth2 eth3).each do |i|
      describe interface(i) do
        it { should exist }
      end

      describe command('ip -0 -o addr show dev eth1') do
        its('stdout') { should_not match /BROADCAST,NOARP,UP,LOWER_UP/ }
        its('stdout') { should match /state DOWN/ }
      end

      describe command('ip -0 -o addr show dev eth2') do
        its('stdout') { should_not match /BROADCAST,NOARP,UP,LOWER_UP/ }
        its('stdout') { should match /state DOWN/ }
      end
    end
  end

  describe command('ip -0 -o addr show dev eth3') do
    its('stdout') { should match /BROADCAST,NOARP,UP,LOWER_UP/ }
  end

  # Test disable
  describe command('ip -o addr show dev eth1') do
    its('stdout') { should_not match %r{inet 10.1.30.20/24} }
  end

  # Test delete
  describe command('ip -o addr show dev eth2') do
    its('stdout') { should_not match %r{inet 10.1.30.20/8} }
  end

  # Test enable
  describe command('ip -o addr show dev eth3') do
    its('stdout') { should match %r{inet 10.1.1.20/24} }
  end

  if os_rel >= 9
    describe file('/etc/nmstate/eth1.yml') do
      it { should exist }
      its('content') { should match /state: down/ }
    end

    describe file('/etc/nmstate/eth2.yml') do
      it { should exist }
      its('content') { should match /name: eth2/ }
      its('content') { should match /enabled: false/ }
      its('content') { should match /type: dummy/ }
      its('content') { should match /state: absent/ }
    end

    describe command 'nmstatectl show -rq eth1' do
      its('exit_status') { should eq 0 }
      its('stdout') { should match /interfaces: \[\]/ }
    end

    describe command 'nmstatectl show -rq eth2' do
      its('exit_status') { should eq 0 }
      its('stdout') { should match /interfaces: \[\]/ }
    end

    describe command 'nmstatectl show -rq eth3' do
      its('exit_status') { should eq 0 }
      its('stdout') { should match /- name: eth3/ }
      its('stdout') { should match /type: dummy/ }
      its('stdout') { should match /state: up/ }
      its('stdout') { should match /ipv4:\n\s+enabled: true/ }
      its('stdout') { should match /ipv6:\n\s+enabled: false/ }
      its('stdout') { should match /- ip: 10.1.1.20\n\s+prefix-length: 24/ }
    end
  else
    describe file('/etc/sysconfig/network-scripts/ifcfg-eth1') do
      it { should exist }
    end

    describe file('/etc/sysconfig/network-scripts/ifcfg-eth2') do
      it { should exist }
      %w(DEVICE=eth2 ONBOOT=no TYPE=none).each do |p|
        its('content') { should match /^#{p}$/ }
      end
    end
  end
end
