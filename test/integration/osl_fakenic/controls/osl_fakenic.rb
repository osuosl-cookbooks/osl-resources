# This control must pass immediately after a converge AND after a manual
# reboot, which is what proves `persist true` works. Both interfaces are
# runtime-only state otherwise, so after a reboot every assertion here
# depends on the systemd units below having recreated them.
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

  # The units are what makes the assertions above survive a reboot.
  %w(dummy1 dummy2).each do |i|
    describe systemd_service("osl-fakenic-#{i}.service") do
      it { should be_installed }
      it { should be_enabled }
    end
  end

  # The body is load-bearing: a wrong Before=, a missing `-`, or `addr add`
  # instead of `addr replace` only fails at the next boot. The path to ip is
  # resolved at converge time and differs by platform, so match the command.
  describe file('/etc/systemd/system/osl-fakenic-dummy2.service') do
    its('content') { should match(/^Before=network-pre\.target NetworkManager\.service$/) }
    its('content') { should match(%r{^ExecStart=-\S+/ip link add name dummy2 type dummy$}) }
    its('content') { should match(%r{^ExecStart=\S+/ip link set dev dummy2 address 00:1a:4b:a6:a7:c4$}) }
    its('content') { should match(%r{^ExecStart=\S+/ip addr replace 192\.168\.0\.1/24 dev dummy2$}) }
    its('content') { should match(%r{^ExecStart=\S+/ip -6 addr replace fe80::1/64 dev dummy2$}) }
  end
end
