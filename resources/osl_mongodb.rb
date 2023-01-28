resource_name :osl_mongodb
provides :osl_mongodb
unified_mode true

default_action :install

property :install_selinux_policy, [true, false], default: true
property :data_dir, String
property :log_dir, String

action :install do
  yum_repository 'mongodb-org-6.0' do
    baseurl 'https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/6.0/x86_64/'
    repo_gpgcheck true
    gpgkey 'https://www.mongodb.org/static/pgp/server-6.0.asc'
  end

  package 'mongodb-org'
  selinux_install 'mogodb-selinux' do
    only_if { new_resource.install_selinux_policy }
  end

  template '/etc/mongod.conf' do
    source 'mongod.conf.erb'
  end

  service 'mongod' do
    action [ :enable, :start ]
  end
end if platform_family?('rhel')
