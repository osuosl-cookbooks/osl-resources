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
property :exclusive, [true, false], default: true

def authorized_keys_path
  ::File.join(dir_path, 'authorized_keys')
end

action :add do
  track_declaration

  directory new_resource.dir_path.to_s do
    owner new_resource.user
    group new_resource.group
    mode '0700'
    recursive true
  end

  if new_resource.exclusive
    keys = new_resource.key.map(&:chomp).reject(&:empty?)
    if keys.empty?
      Chef::Log.warn("#{declaration_name} is exclusive with no keys for #{new_resource.authorized_keys_path}; leaving the file as it is")
    else
      keys_state[:keys].concat(keys)
      declare_exclusive_file
    end
  else
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
end

action :remove do
  # Removed keys win over any exclusive :add, before or after this one
  state = keys_state
  state[:removed].concat(new_resource.key.map(&:chomp))

  new_resource.key.each do |key|
    line_delete_lines "#{new_resource.user}-#{key_sha(key)}" do
      path "#{new_resource.dir_path}/authorized_keys"
      # line wraps a String pattern in /.../ unescaped, so "+" in a key never matched
      pattern(/^#{Regexp.escape(key)}$/)
    end
  end

  # Keep both while the delayed exclusive write still has keys to put here
  file "#{new_resource.dir_path}/authorized_keys" do
    action :delete
    only_if { ::File.empty?("#{new_resource.dir_path}/authorized_keys") }
    not_if { (state[:keys].uniq - state[:removed]).any? }
  end

  directory new_resource.dir_path do
    action :delete
    only_if { ::Dir.empty?(new_resource.dir_path) }
    not_if { (state[:keys].uniq - state[:removed]).any? }
  end
end

action_class do
  require 'digest/sha1'
  require 'English'

  private

  def key_sha(key)
    Digest::SHA1.hexdigest(key)[0, 8]
  end

  def declaration_name
    "#{new_resource} (#{new_resource.source_line})"
  end

  def keys_state
    node.run_state['osl_authorized_keys'] ||= {}
    node.run_state['osl_authorized_keys'][new_resource.authorized_keys_path] ||= { keys: [], removed: [], decls: [] }
  end

  # An exclusive file plus line appends would change every run, and merged
  # exclusive declarations must agree on who owns the file.
  def track_declaration
    path = new_resource.authorized_keys_path
    keys_state[:decls].each do |other|
      if other[:exclusive] != new_resource.exclusive
        raise "#{other[:name]} and #{declaration_name} both manage #{path}, but only one sets exclusive"
      end
      next unless new_resource.exclusive
      next if other[:user] == new_resource.user && other[:group] == new_resource.group
      raise "#{other[:name]} and #{declaration_name} set exclusive on #{path} with different user or group"
    end
    keys_state[:decls] << {
      name: declaration_name,
      exclusive: new_resource.exclusive,
      user: new_resource.user,
      group: new_resource.group,
    }
  end

  # One file per path in the root run context, written after every exclusive
  # declaration has added its keys; skipped when the run is failing.
  def declare_exclusive_file
    state = keys_state
    file_path = new_resource.authorized_keys_path
    file_owner = new_resource.user
    file_group = new_resource.group
    with_run_context(:root) do
      find_resource(:file, "osl_authorized_keys #{file_path}") do
        path file_path
        content lazy { (state[:keys].uniq - state[:removed]).map { |k| "#{k}\n" }.join }
        owner file_owner
        group file_group
        mode '0600'
        only_if { (state[:keys].uniq - state[:removed]).any? }
        not_if { !$ERROR_INFO.nil? }
        action :nothing
        delayed_action :create
      end
    end
  end
end
