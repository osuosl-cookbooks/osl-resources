provides :osl_ipmi_user
resource_name :osl_ipmi_user
unified_mode true

default_action :create

property :username, String,
  name_property: true,
  callbacks: {
    'must be 16 characters or less' => lambda { |u|
      u.length <= 16
    },
  }
property :password, String,
  required: [:create],
  sensitive: true,
  callbacks: {
    'must be 20 characters or less (IPMI 2.0 limit)' => lambda { |p|
      p.length <= 20
    },
  }
property :privilege, [Integer, Symbol],
  required: [:create],
  coerce: proc { |p| ipmi_privilege_to_int(p) },
  callbacks: {
    'must be between 1 and 5 or a valid symbol (:callback, :user, :operator, :administrator, :oem)' => lambda { |p|
      p.is_a?(Integer) && p.between?(1, 5)
    },
  }
property :channel, Integer, default: 1
property :enabled, [true, false], default: true
property :min_slot, Integer, default: 3

action :create do
  unless ipmi_available?
    Chef::Log.warn("osl_ipmi_user[#{new_resource.username}]: No IPMI device found, skipping")
    return
  end

  package 'ipmitool'

  # Validate password length against IPMI version
  max_len = ipmi_max_password_length
  if new_resource.password.length > max_len
    raise "Password exceeds maximum length of #{max_len} characters for IPMI #{ipmi_version}"
  end

  slot = ipmi_find_user_slot(new_resource.username, new_resource.channel)
  current_state = ipmi_current_user_state(new_resource.username, new_resource.channel)

  if slot.nil?
    # User does not exist, find next available slot and create
    slot = ipmi_next_available_slot(new_resource.channel, new_resource.min_slot)

    if slot.nil?
      Chef::Log.warn("osl_ipmi_user[#{new_resource.username}]: No available IPMI user slots")
      return
    end

    converge_by("create IPMI user '#{new_resource.username}' in slot #{slot}") do
      ipmi_set_username(slot, new_resource.username)
      ipmi_set_password(slot, new_resource.password)
      ipmi_save_password_hash(new_resource.username, new_resource.password)
      ipmi_set_privilege(slot, new_resource.privilege, new_resource.channel)
      ipmi_set_enabled(slot, new_resource.enabled, new_resource.channel)
    end
  else
    # User exists, check if updates are needed
    if current_state[:privilege] != new_resource.privilege
      converge_by("update IPMI user '#{new_resource.username}' privilege from #{current_state[:privilege]} to #{new_resource.privilege}") do
        ipmi_set_privilege(slot, new_resource.privilege, new_resource.channel)
      end
    end

    if current_state[:enabled] != new_resource.enabled
      converge_by("#{new_resource.enabled ? 'enable' : 'disable'} IPMI user '#{new_resource.username}'") do
        ipmi_set_enabled(slot, new_resource.enabled, new_resource.channel)
      end
    end
  end
end

action :delete do
  unless ipmi_available?
    Chef::Log.warn("osl_ipmi_user[#{new_resource.username}]: No IPMI device found, skipping")
    return
  end

  package 'ipmitool'

  slot = ipmi_find_user_slot(new_resource.username, new_resource.channel)

  if slot.nil?
    Chef::Log.debug("osl_ipmi_user[#{new_resource.username}]: User does not exist, nothing to delete")
    return
  end

  if slot < new_resource.min_slot
    Chef::Log.warn("osl_ipmi_user[#{new_resource.username}]: Cannot delete user in protected slot #{slot}")
    return
  end

  converge_by("delete IPMI user '#{new_resource.username}' from slot #{slot}") do
    ipmi_disable_user(slot, new_resource.channel)
    ipmi_clear_username(slot)
    ipmi_remove_password_hash(new_resource.username)
  end
end

action :modify do
  unless ipmi_available?
    Chef::Log.warn("osl_ipmi_user[#{new_resource.username}]: No IPMI device found, skipping")
    return
  end

  package 'ipmitool'

  # Validate password length against IPMI version if password is being set
  if new_resource.password
    max_len = ipmi_max_password_length
    if new_resource.password.length > max_len
      raise "Password exceeds maximum length of #{max_len} characters for IPMI #{ipmi_version}"
    end
  end

  slot = ipmi_find_user_slot(new_resource.username, new_resource.channel)

  if slot.nil?
    Chef::Log.warn("osl_ipmi_user[#{new_resource.username}]: User does not exist, cannot modify")
    return
  end

  current_state = ipmi_current_user_state(new_resource.username, new_resource.channel)

  if new_resource.privilege && current_state[:privilege] != new_resource.privilege
    converge_by("update IPMI user '#{new_resource.username}' privilege from #{current_state[:privilege]} to #{new_resource.privilege}") do
      ipmi_set_privilege(slot, new_resource.privilege, new_resource.channel)
    end
  end

  if new_resource.password && ipmi_password_needs_update?(new_resource.username, new_resource.password)
    converge_by("update IPMI user '#{new_resource.username}' password") do
      ipmi_set_password(slot, new_resource.password)
      ipmi_save_password_hash(new_resource.username, new_resource.password)
    end
  end

  if current_state[:enabled] != new_resource.enabled
    converge_by("#{new_resource.enabled ? 'enable' : 'disable'} IPMI user '#{new_resource.username}'") do
      ipmi_set_enabled(slot, new_resource.enabled, new_resource.channel)
    end
  end
end

action_class do
  include ::OSLResources::Cookbook::Helpers
end
