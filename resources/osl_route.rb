resource_name :osl_route
provides :osl_route
unified_mode true

default_action :add

provides :osl_route, platform_family: 'rhel'
property :routes, Array, required: [:add]
property :device, String, name_property: true
property :nmstate, [true, false], default: lazy { default_nmstate }

action :add do
  package 'nmstate' if new_resource.nmstate

  directory '/etc/nmstate' if new_resource.nmstate

  template "/etc/nmstate/route-#{new_resource.device}.yml" do
    source 'nmstate-route.yml.erb'
    cookbook 'osl-resources'
    mode '0640'
    variables(
      routes: nmstate_routes,
      state: nil
    )
    notifies :run, "execute[nmstatectl apply -q /etc/nmstate/route-#{new_resource.device}.yml]", :immediately
  end if new_resource.nmstate

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
  end unless new_resource.nmstate

  execute "route-ifup #{new_resource.device}" do
    command "ifup #{new_resource.device}"
    action :nothing
  end unless new_resource.nmstate

  execute "nmstatectl apply -q /etc/nmstate/route-#{new_resource.device}.yml" do
    action :nothing
  end if new_resource.nmstate
end

action :remove do
  package 'nmstate' if new_resource.nmstate

  template "/etc/nmstate/route-#{new_resource.device}.yml" do
    source 'nmstate-route.yml.erb'
    cookbook 'osl-resources'
    mode '0640'
    variables(
      routes: nmstate_routes,
      state: 'absent'
    )
    notifies :run, "execute[nmstatectl apply -q /etc/nmstate/route-#{new_resource.device}.yml]", :immediately
  end if new_resource.nmstate

  file "/etc/sysconfig/network-scripts/route-#{new_resource.device}" do
    action :delete
    notifies :run, "execute[route-ifup #{new_resource.device}]", :immediately
  end unless new_resource.nmstate

  execute "route-ifup #{new_resource.device}" do
    command "ifup #{new_resource.device}"
    action :nothing
  end unless new_resource.nmstate

  execute "nmstatectl apply -q /etc/nmstate/route-#{new_resource.device}.yml" do
    action :nothing
  end if new_resource.nmstate
end
