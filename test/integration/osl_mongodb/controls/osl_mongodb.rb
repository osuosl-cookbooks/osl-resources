control 'osl_mongodb' do
  describe yum.repo('mongodb-org') do
    it { should exist }
    its('baseurl') { should cmp %r{https://repo\.mongodb\.org/yum/redhat/[0-9]+/mongodb-org/[0-9]+\.[0-9]/.+} }
    it { should be_enabled }
  end

  describe package('mongodb-org') do
    it { should be_installed }
  end

  describe file('/etc/mongod.conf') do
    it { should exist }
    its('owner') { should cmp 'root' }
    its('group') { should cmp 'root' }
    its('mode') { should cmp '0644' }
    its('content') do
        should match <<~EOF.strip
          net:
            port: 27017
            bindIp: 127.0.0.1
            maxIncomingConnections: 65536
          processManagement:
            fork: true
            pidFilePath: /var/run/mongodb/mongod.pid
            timeZoneInfo: /usr/share/zoneinfo
          storage:
            dbPath: /var/lib/mongo
            journal:
              enabled: true
          systemLog:
            destination: file
            logAppend: true
            path: /var/log/mongodb/mongod.log
        EOF
    end
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
