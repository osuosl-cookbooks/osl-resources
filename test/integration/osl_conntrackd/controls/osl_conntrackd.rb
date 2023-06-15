ip_address = inspec.interfaces.ipv4_address
interface = inspec.interfaces.names.first

control 'osl_conntrackd' do
  describe package 'conntrack-tools' do
    it { should be_installed }
  end

  describe file '/etc/conntrackd/conntrackd.conf' do
    its('content') { should match /Interface #{interface}/ }
    its('content') { should match /IPv4_Destination_Address 127.0.0.1/ }
    its('content') { should match /^    IPv4_address #{ip_address}/ }
    its('content') { should match /^      IPv4_address #{ip_address}/ }
    its('content') { should match /^      IPv4_address 127.0.0.1/ }
  end

  describe file '/etc/conntrackd/primary-backup.sh' do
    it { should be_executable }
    it { should exist }
  end

  describe service 'conntrackd' do
    it { should be_enabled }
    it { should be_running }
  end
end
