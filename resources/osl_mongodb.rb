resource_name :osl_mongodb
provides :osl_mongodb, platform_family: 'rhel'
unified_mode true

default_action :install

property :version, String, default: '6.0'
property :install_selinux_policy, [true, false], default: true
property :data_dir, String
property :log_dir, String
property :port, String
property :bind_ip, String

action :install do
  yum_repository 'mongodb-org' do
    baseurl "https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/#{new_resource.version}/$basearch/"
    repo_gpgcheck true
    gpgkey "https://www.mongodb.org/static/pgp/server-#{new_resource.version}.asc"
  end

  package 'mongodb-org'

  selinux_install 'mongodb-selinux' do
    only_if { "#{new_resource.install_selinux_policy}" }
  end

  selinux_port "#{new_resource.port}" do
    protocol 'tcp'
    secontext 'mongod_port_t'
  end

  template '/etc/mongod.conf' do
    source 'mongod.conf.erb'
  end

  service 'mongod' do
    action [ :enable, :start ]
  end
end
