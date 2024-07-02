resource_name :osl_dnsdist
provides :osl_dnsdist
unified_mode true

default_action :create

property :acls, Array
property :console_address, String, default: '127.0.0.1'
property :console_key, String, sensitive: true
property :extra_options, Array
property :gpgkey, String, default: 'https://repo.powerdns.com/FD380FBB-pub.asc'
property :instance, String, name_property: true
property :listen_addresses, Array, default: %w(127.0.0.1 ::1)
property :netmask_groups, Hash
property :server_policy, String, default: 'firstAvailable'
property :servers, Hash, required: true
property :version, String, default: '1.7'
property :webserver_acl, Array, default: %w(127.0.0.1 ::1)
property :webserver_address, String, default: '127.0.0.1:8083'
property :webserver_password, String, sensitive: true

action :create do
  include_recipe 'osl-repos::epel'

  yum_repository 'dnsdist' do
    baseurl "https://repo.powerdns.com/el/$basearch/$releasever/dnsdist-#{dnsdist_ver}"
    description "PowerDNS repository for dnsdist - version #{new_resource.version}"
    gpgcheck true
    gpgkey new_resource.gpgkey
    priority '90'
    includepkgs 'dnsdist*'
  end

  package 'dnsdist'

  template "/etc/dnsdist/acl-#{new_resource.name}" do
    cookbook 'osl-resources'
    source 'dnsdist-common.conf.erb'
    variables(items: new_resource.acls.sort)
    owner 'dnsdist'
    group 'dnsdist'
    mode '0700'
    notifies :restart, "service[#{dnsdist_service}]"
  end if new_resource.acls

  template "/etc/dnsdist/dnsdist-#{new_resource.name}.conf" do
    cookbook 'osl-resources'
    source 'dnsdist.conf.erb'
    sensitive true
    variables(
      acls: new_resource.acls,
      console_address: new_resource.console_address,
      console_key: new_resource.console_key,
      extra_options: new_resource.extra_options,
      instance_name: new_resource.name,
      listen_addresses: new_resource.listen_addresses.sort,
      netmask_groups: dnsdist_netmask_groups,
      server_policy: new_resource.server_policy,
      servers: dnsdist_servers(new_resource.servers),
      webserver_acl: new_resource.webserver_acl.join(','),
      webserver_address: new_resource.webserver_address,
      webserver_password: new_resource.webserver_password
    )
    owner 'dnsdist'
    group 'dnsdist'
    mode '0700'
    notifies :restart, "service[#{dnsdist_service}]"
  end

  service dnsdist_service do
    action [:enable, :start]
  end

  osl_systemd_unit_enable dnsdist_service
end
