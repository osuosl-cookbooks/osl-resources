control 'osl_mongodb' do
  describe yum.repo('mongodb-org') do
    it { should exist }
    its('baseurl') { should cmp /https:\/\/repo\.mongodb\.org\/yum\/redhat\/[0-9]+\/mongodb-org\/[0-9]+\.[0-9]\/.+/ }
    it { should be_enabled }
  end

  describe package('mongodb-org') do
    it { should be_installed }
  end

  describe file ('/etc/mongod.conf') do
    it { should exist }
    its('owner') { should cmp 'mongod' }
    its('group') { should cmp 'mongod' }
    its('mode') { should cmp '0644' }
    its('content') { should cmp /net:/ }
    its('content') { should cmp /port: [0-9]+/ }
    its('content') { should cmp /bindIp: [0-9]+\.[0-9]+\.[0-9]+.[0-9]+/ }
    its('content') { should cmp /maxIncomingConnections: [0-9]+/ }
    its('content') { should cmp /processManagement:/ }
    its('content') { should cmp /fork: [false|true]/ }
    its('content') { should cmp /pidFilePath: .+/ }
    its('content') { should cmp /timeZoneInfo: .+/ }
    its('content') { should cmp /storage:/ }
    its('content') { should cmp /dbPath: .+/ }
    its('content') { should cmp /journal:/ }
    its('content') { should cmp /enabled: true/ }
    its('content') { should cmp /systemLog:/ }
    its('content') { should cmp /destination: .+/ }
    its('content') { should cmp /logAppend: [false|true]/ }
    its('content') { should cmp /path: .+/ }
  end

   describe file('/etc/sysctl.d/99-chef-vm.max_map_count.conf') do
    its('content') { should cmp /vm\.max_map_count = [0-9]+/ }
  end

  describe service('mongod') do
    it { should be_enabled }
    it { should be_running }
  end

  describe port(27017) do
    it { should be_listening }
  end

  describe host('127.0.0.1', port: 27017) do
    it { should be_reachable }
    it { should be_resolvable }
  end

  describe directory('/var/lib/mongo') do
    it { should exist }
    its('owner') { should cmp 'mongod' }
    its('group') { should cmp 'mongod' }
  end

  describe file('/var/log/mongodb/mongod.log') do
    it { should exist }
    its('owner') { should cmp 'mongod' }
    its('group') { should cmp 'mongod' }
  end

  describe port(27017) do
    it { should be_listening }
  end
end
