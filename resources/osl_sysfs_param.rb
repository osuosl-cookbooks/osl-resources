resource_name :osl_sysfs_param
provides :osl_sysfs_param
unified_mode true

default_action :set

property :param_path, String, name_property: true
property :value, [String, Integer], required: true, coerce: proc { |v| v.to_s.strip }
property :ignore_missing, [true, false], default: false
property :persist, [true, false], default: false

action :set do
  path = new_resource.param_path
  desired = new_resource.value

  if ::File.exist?(path)
    if osl_sysfs_param_has_value?(path, desired)
      Chef::Log.debug("osl_sysfs_param: #{path} is already set to #{desired}")
    else
      converge_by("set sysfs parameter #{path} from #{osl_sysfs_param_read(path)} to #{desired}") do
        osl_sysfs_param_write(path, desired)
      end
    end
  elsif new_resource.ignore_missing
    Chef::Log.warn("osl_sysfs_param: #{path} does not exist, skipping")
  else
    raise Chef::Exceptions::FileNotFound,
      "osl_sysfs_param: #{path} does not exist; the module or subsystem providing it may not be loaded"
  end

  # Reapply the value at boot via a systemd-tmpfiles fragment. A tmpfiles
  # `w` line writes only when the target exists (verified: silent skip,
  # exit 0), so this is safe to lay down even for a parameter guarded by
  # ignore_missing that is absent right now. Managed after the block above
  # so a raise on a missing parameter does not leave boot config behind.
  # `persist false` removes the fragment this resource would have created,
  # so toggling it off cleans up after itself.
  if new_resource.persist
    file osl_sysfs_param_tmpfiles_path(path) do
      content osl_sysfs_param_tmpfiles_line(path, desired)
      mode '0644'
    end
  else
    file osl_sysfs_param_tmpfiles_path(path) do
      action :delete
    end
  end
end
