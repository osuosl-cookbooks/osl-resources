resource_name :osl_mongodb
provides :osl_mongodb, platform_family: 'rhel'
unified_mode true

default_action :install

property :version, String, default: '6.0'
property :install_selinux_policy, [true, false], default: true
property :data_dir, String, default: '/var/lib/mongo'
property :log_dest, %w(syslog file), default: 'syslog'
property :log_path, String
property :port, String, default: '27017'
property :bind_ip, String, default: 'localhost'

action :install do
  yum_repository 'mongodb-org' do
    baseurl "https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/#{new_resource.version}/$basearch/"
    repo_gpgcheck true
    gpgkey "https://www.mongodb.org/static/pgp/server-#{new_resource.version}.asc"
  end

  package 'mongodb-org'

=begin
  selinux_install 'mongodb-selinux' do
    only_if { "#{new_resource.install_selinux_policy}" }
  end

  selinux_port "#{new_resource.port}" do
    protocol 'tcp'
    secontext 'mongod_port_t'
  end
=end

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
      bind_ip: new_resource.bind_ip
    )
    notifies :restart, 'service[mongod]', :immediately
  end

  service 'mongod' do
    action [ :enable, :start ]
  end

  file "#{new_resource.data_dir}" do
    owner 'mongod'
    group 'mongod'
  end

  file "#{new_resource.log_path}" do
    owner 'mongod'
    group 'mongod'
    not_if { new_resource.log_path.nil? }
  end
end
