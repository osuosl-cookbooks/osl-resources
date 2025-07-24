provides :osl_ssh_key
resource_name :osl_ssh_key
unified_mode true

default_action :add

property :key_name, String, name_property: true
property :content, String, required: [:add], sensitive: true
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

  file "#{new_resource.dir_path}/#{new_resource.key_name}" do
    sensitive true
    owner new_resource.user
    group new_resource.group
    mode '0600'
    content new_resource.content
  end
end

action :remove do
  file "#{new_resource.dir_path}/#{new_resource.key_name}" do
    sensitive true
    action :delete
  end

  directory new_resource.dir_path do
    action :delete
    only_if { ::Dir.empty?(new_resource.dir_path) }
  end
end
