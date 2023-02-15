control 'osl_mongodb_paramters' do
  describe yum.repo('mongodb-org') do
    it { should exist }
    its('baseurl') { should cmp %r{https\:\/\/repo\.mongodb\.org\/yum\/redhat\/[0-9]+\/mongodb-org\/4\.4\/.+} }
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
            port: 27072
            bindIp: 0.0.0.0
            maxIncomingConnections: 102400
          processManagement:
            fork: true
            pidFilePath: /var/run/mongodb/mongod.pid
            timeZoneInfo: /usr/share/zoneinfo
          storage:
            dbPath: /var/lib/mongo2
            journal:
              enabled: true
          systemLog:
            destination: syslog
            logAppend: true
        EOF
    end
  end

  describe service('mongod') do
    it { should be_enabled }
    it { should be_running }
  end

  describe port(27072) do
    it { should be_listening }
  end

  describe host('127.0.0.1', port: 27072) do
    it { should be_reachable }
    it { should be_resolvable }
  end

  describe host('126.0.0.1', port: 27072) do
    it { should be_reachable }
    it { should be_resolvable }
  end

  describe directory('/var/lib/mongo2') do
    it { should exist }
    its('owner') { should cmp 'mongod' }
    its('group') { should cmp 'mongod' }
  end
end
