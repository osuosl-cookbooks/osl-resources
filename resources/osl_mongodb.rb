resource_name :osl_mongodb
provides :osl_mongodb
unified_mode true

default_action :install

action :install do

  yum_repository 'mongodb-org-6.0' do
    baseurl 'https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/6.0/x86_64/'
    repo_gpgcheck true
    gpgkey 'https://www.mongodb.org/static/pgp/server-6.0.asc'
  end

  package mongodb-org

  template '/etc/mongod.conf' do
    source 'mongod.erb'
  end


  service 'mongod' do
    action [ :enable, :start ]
  end

end if platform_family?('rhel')
