provides :osl_authorized_keys
resource_name :osl_authorized_keys
unified_mode true

default_action :add

property :key, String, name_property: true
property :user, String, required: true
property :group, String, default: lazy { user }
property :dir_path, String, default: lazy { "/home/#{user}/.ssh" }

action :add do
  directory "#{new_resource.dir_path}" do
    owner new_resource.user
    group new_resource.group
    mode '0700'
    recursive true
  end

  line_append_if_no_line "#{new_resource.user}-#{new_resource.key}" do
    path "#{new_resource.dir_path}/authorized_keys"
    line new_resource.key
    owner new_resource.user
    group new_resource.group
    mode '0600'
  end
end

action :remove do
  line_delete_lines "#{new_resource.user}-#{new_resource.key}" do
    path "#{new_resource.dir_path}/authorized_keys"
    pattern "^#{new_resource.key}$"
  end

  file "#{new_resource.dir_path}/authorized_keys" do
    action :delete
    only_if { ::File.empty?("#{new_resource.dir_path}/authorized_keys") }
  end

  directory new_resource.dir_path do
    action :delete
    only_if { ::Dir.empty?(new_resource.dir_path) }
  end
end
