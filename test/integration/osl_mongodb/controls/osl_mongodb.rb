control 'osl_mongodb' do
  describe yum.repo('mongodb-org') do
    it { should exist }
    its('baseurl') { should cmp 'https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/5.0/x86_64/' }
    it { should be_enabled }
  end

  describe package('mongodb-org') do
    it { should be_installed }
  end

  describe file('/var/lib/mongo') do
    it { should exist }
    its('owner') { should cmp 'mongod' }
    its('group') { should cmp 'mongod' }
  end

  describe file('/var/lib/mongodb') do
    it { should exist }
    its('owner') { should cmp 'mongod' }
    its('group') { should cmp 'mongod' }
  end

  describe file('/etc/mongod.conf') do
    it { should exist }
  end

  describe service('mongod') do
    it { should be_enabled }
    it { should be_running }
  end

  describe port(27017) do
    it { should be_listening }
  end
end
