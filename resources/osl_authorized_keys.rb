provides :osl_authorized_keys
resource_name :osl_authorized_keys
unified_mode true

default_action :add

property :key, [String, Array],
  name_property: true,
  coerce: proc { |k| Array(k) }
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

  new_resource.key.each do |key|
    line_append_if_no_line "#{new_resource.user}-#{key_sha(key)}" do
      path "#{new_resource.dir_path}/authorized_keys"
      line key
      owner new_resource.user
      group new_resource.group
      mode '0600'
    end
  end
end

action :remove do
  new_resource.key.each do |key|
    line_delete_lines "#{new_resource.user}-#{key_sha(key)}" do
      path "#{new_resource.dir_path}/authorized_keys"
      pattern "^#{key}$"
    end
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

action_class do
  require 'digest/sha1'

  private

  def key_sha(key)
    Digest::SHA1.hexdigest(key)[0, 8]
  end
end
