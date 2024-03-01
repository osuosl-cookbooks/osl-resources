resource_name :osl_udev_rules
provides :osl_udev_rules, platform_family: 'rhel'
default_action :add
unified_mode true

property :rule, String, name_property: true
property :persistent_net, [true, false], default: true

action_class do
  include OSLResources::Cookbook::ResourceHelpers
end

action :add do
  osl_udev_rules_resource_init
  osl_udev_rules_resource.variables['rules'] ||= []
  osl_udev_rules_resource.variables['rules'] << new_resource.rule

  file '/etc/udev/rules.d/70-persistent-net.rules' do
    action :delete
    notifies :run, 'execute[reload udev]', :delayed
  end unless new_resource.persistent_net
end
