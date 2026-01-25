resource_name :osl_dnf_copr
provides :osl_dnf_copr, platform_family: 'rhel'
unified_mode true

default_action :enable

property :copr, String, name_property: true

action :enable do
  package 'dnf-plugins-core'

  execute "dnf copr enable #{new_resource.copr}" do
    command "dnf -y copr enable #{new_resource.copr}"
    not_if { copr_enabled?(new_resource.copr) }
    notifies :run, "execute[dnf makecache #{new_resource.copr}]", :immediately
    notifies :flush_cache, "package[package-cache-reload-#{new_resource.copr}]", :immediately
  end

  execute "dnf makecache #{new_resource.copr}" do
    command 'dnf makecache'
    action :nothing
  end

  package "package-cache-reload-#{new_resource.copr}" do
    action :nothing
  end
end

action :disable do
  execute "dnf copr remove #{new_resource.copr}" do
    command "dnf -y copr remove #{new_resource.copr}"
    only_if { copr_enabled?(new_resource.copr) }
  end
end
