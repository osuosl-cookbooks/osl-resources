resource_name :osl_fakenic
provides :osl_fakenic
unified_mode true

default_action :create

property :interface, String, name_property: true
property :ip4, [String, Array], coerce: proc { |v| v.nil? ? nil : Array(v) }
property :ip6, [String, Array], coerce: proc { |v| v.nil? ? nil : Array(v) }
property :mac_address, String
property :multicast, [true, false], default: false
property :persist, [true, false], default: true

action :create do
  package 'network-scripts' if platform_family?('rhel') && node['platform_version'].to_i == 8

  kernel_module 'dummy' unless docker?

  execute "add fake interface #{new_resource.interface}" do
    command "ip link add name #{new_resource.interface} type dummy"
    not_if "ip a show dev #{new_resource.interface}"
  end

  execute "bring fake #{new_resource.interface} online" do
    command "ip link set dev #{new_resource.interface} up"
    not_if "ip a show dev #{new_resource.interface} | grep UP"
  end

  new_resource.ip4.each do |ip|
    execute "add IPv4 #{ip} to #{new_resource.interface}" do
      command "ip addr add #{ip} dev #{new_resource.interface}"
      not_if "ip a show dev #{new_resource.interface} | grep #{ip}"
    end
  end if new_resource.ip4

  new_resource.ip6.each do |ip|
    execute "add IPv6 #{ip} to #{new_resource.interface}" do
      command "ip -6 addr add #{ip} dev #{new_resource.interface}"
      not_if "ip -6 a show dev #{new_resource.interface} | grep #{ip}"
    end
  end if new_resource.ip6

  execute "Set MAC address #{new_resource.mac_address} on #{new_resource.interface}" do
    command "ip link set dev #{new_resource.interface} address #{new_resource.mac_address}"
    not_if "ip -o link show dev #{new_resource.interface} | grep #{new_resource.mac_address}"
  end if new_resource.mac_address

  execute "enable multicast on #{new_resource.interface}" do
    command "ip link set #{new_resource.interface} multicast on"
    not_if "ip a show dev #{new_resource.interface} | grep MULTICAST"
  end if new_resource.multicast

  # A dummy device is runtime-only state, so nothing above survives a reboot.
  # This lays down a boot-time unit recreating exactly what the action creates
  # -- the device and the properties osl_fakenic owns -- and stops there,
  # leaving anything layered on top to whatever manages it. `persist false`
  # opts out and removes any unit an earlier run created.
  if new_resource.persist && !docker?
    unit = osl_fakenic_unit_name(new_resource.interface)

    # A local, not a helper call inside the block: Chef's method_missing
    # forwards with *args, turning keywords into a positional Hash on Ruby 3.
    unit_content = osl_fakenic_unit_content(
      interface: new_resource.interface,
      ip_path: osl_fakenic_ip_path,
      ip4: new_resource.ip4,
      ip6: new_resource.ip6,
      mac_address: new_resource.mac_address,
      multicast: new_resource.multicast
    )

    # systemd_unit defaults to :nothing, so the action is not optional.
    systemd_unit unit do
      content unit_content
      action :create
    end

    # Started as well as enabled, so a broken unit fails this converge rather
    # than the reboot it was written for. Every ExecStart is idempotent, so it
    # runs clean against the device the executes above just created.
    service unit do
      action [:enable, :start]
      subscribes :restart, "systemd_unit[#{unit}]"
    end
  else
    osl_fakenic_remove_unit
  end
end

action :delete do
  package 'network-scripts' if platform_family?('rhel') && node['platform_version'].to_i == 8

  # Before the teardown, so a reboot cannot resurrect a deleted interface.
  osl_fakenic_remove_unit

  kernel_module 'dummy' unless docker?

  execute "bring fake #{new_resource.interface} offline" do
    command "ip link set dev #{new_resource.interface} down"
    only_if(
      "ip link show dev #{new_resource.interface} | grep UP && " \
      "ip -details link show dev #{new_resource.interface} | tail -1 | grep dummy"
    )
  end

  execute "remove fake interface #{new_resource.interface}" do
    command "ip link delete #{new_resource.interface}"
    only_if(
      "ip link show dev #{new_resource.interface} && " \
      "ip -details link show dev #{new_resource.interface} | tail -1 | grep dummy"
    )
  end
end

action_class do
  # `persist false` and :delete both clean up whatever an earlier run created.
  # Guarded on the file existing so opting out costs no systemctl round trips
  # once the unit is gone.
  def osl_fakenic_remove_unit
    return if docker?
    return unless ::File.exist?(osl_fakenic_unit_path(new_resource.interface))

    unit = osl_fakenic_unit_name(new_resource.interface)

    service unit do
      action [:stop, :disable]
    end

    systemd_unit unit do
      action :delete
    end
  end
end
