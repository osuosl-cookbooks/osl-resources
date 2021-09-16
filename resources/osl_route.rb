resource_name :osl_route
provides :osl_route
unified_mode true

default_action :add

provides :osl_route, platform_family: 'rhel'
property :routes, Array, required: [:add]
property :device, String, name_property: true

action :add do
  template "/etc/sysconfig/network-scripts/route-#{new_resource.device}" do
    source 'route.conf.erb'
    cookbook 'osl-resources'
    owner 'root'
    group 'root'
    mode '0640'
    variables(
      routes: new_resource.routes
    )
    notifies :run, "execute[route-ifup #{new_resource.device}]", :immediately
  end

  execute "route-ifup #{new_resource.device}" do
    command "ifup #{new_resource.device}"
    action :nothing
  end
end

action :remove do
  file "/etc/sysconfig/network-scripts/route-#{new_resource.device}" do
    action :delete
    notifies :run, "execute[route-ifup #{new_resource.device}]", :immediately
  end

  execute "route-ifup #{new_resource.device}" do
    command "ifup #{new_resource.device}"
    action :nothing
  end
end
