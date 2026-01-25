control 'osl_hpnssh' do
  describe yum.repo 'copr:copr.fedorainfracloud.org:rapier1:hpnssh' do
    it { should exist }
    it { should be_enabled }
  end

  %w(hpnssh hpnssh-clients hpnssh-server).each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end

  describe service('hpnsshd') do
    it { should be_enabled }
    it { should be_running }
  end

  describe file('/etc/hpnssh/sshd_config') do
    its('owner') { should cmp 'root' }
    its('group') { should cmp 'root' }
    its('mode') { should cmp '0600' }
  end

  describe sshd_config('/etc/hpnssh/sshd_config') do
    its('Port') { should cmp 2222 }
    its('AuthorizedKeysFile') { should cmp '.ssh/authorized_keys' }
    its('Subsystem') { should cmp 'sftp /usr/libexec/hpnssh/hpnsftp-server' }
    its('UseDNS') { should cmp 'no' }
    its('PermitRootLogin') { should cmp 'prohibit-password' }
  end

  describe port(2222) do
    it { should be_listening }
    its('processes') { should include 'hpnsshd' }
  end
end
