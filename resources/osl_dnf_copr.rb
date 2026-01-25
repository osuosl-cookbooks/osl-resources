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
  end
end

action :disable do
  execute "dnf copr remove #{new_resource.copr}" do
    command "dnf -y copr remove #{new_resource.copr}"
    only_if { copr_enabled?(new_resource.copr) }
  end
end
