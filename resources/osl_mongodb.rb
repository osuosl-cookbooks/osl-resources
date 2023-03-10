resource_name :osl_mongodb
provides :osl_mongodb, platform_family: 'rhel'
unified_mode true

default_action :install

property :version, String, name_property: true
property :data_dir, String, default: '/var/lib/mongo/'
property :log_dest, %w(syslog file), default: 'file'
property :log_path, String, default: '/var/log/mongodb/mongod.log'
property :port, Integer, default: 27017
property :bind_ip, String, default: '127.0.0.1'
property :max_connections, Integer, default: 65536
property :pid_file_path, String, default: '/var/run/mongodb/mongod.pid'

action :install do
  yum_repository 'mongodb-org' do
    baseurl "https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/#{new_resource.version}/$basearch/"
    repo_gpgcheck true
    gpgkey "https://www.mongodb.org/static/pgp/server-#{new_resource.version}.asc"
  end

  package 'mongodb-org'

  directory "#{new_resource.data_dir}" do
    owner 'mongod'
    group 'mongod'
    mode '0770'
    recursive true
  end

  file "#{new_resource.log_path}" do
    owner 'mongod'
    group 'mongod'
    mode '0600'
    only_if { new_resource.log_dest == 'file' }
  end

  template '/etc/mongod.conf' do
    source 'mongod.conf.erb'
    cookbook 'osl-resources'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      data_dir: new_resource.data_dir,
      log_dest: new_resource.log_dest,
      log_path: new_resource.log_path,
      port: new_resource.port,
      bind_ip: new_resource.bind_ip,
      max_connections: new_resource.max_connections,
      pid_file_path: new_resource.pid_file_path
    )
    notifies :restart, 'service[mongod]'
  end

  service 'mongod' do
    action [:enable, :start]
  end
end
