resource_name :osl_ifconfig
provides :osl_ifconfig
unified_mode true

default_action :add

provides :osl_ifconfig, platform_family: 'rhel'
property :bcast, String
property :bonding_opts, String
property :bond_ports,
  [String, Array],
  coerce: proc { |v| v.nil? ? nil : Array(v) },
  default: []
property :bootproto, String
property :bridge, String
property :bridge_options, Hash
property :bridge_ports,
  [String, Array],
  coerce: proc { |v| v.nil? ? nil : Array(v) },
  default: []
property :defroute, String
property :delay, String
property :device, String, name_property: true
property :ethtool_opts, String
property :force, [true, false], default: false
property :gateway, String
property :hwaddr, String
property :ipv4addr,
  [String, Array],
  coerce: proc { |v| v.nil? ? nil : Array(v) },
  default: []
property :ipv6addr,
  [String, Array],
  coerce: proc { |v| v.nil? ? nil : Array(v) },
  default: []
property :ipv6addrsec, Array
property :ipv6_autoconf, String
property :ipv6_defaultgw, String
property :ipv6init, String
property :mask,
  [String, Array],
  coerce: proc { |v| v.nil? ? nil : Array(v) },
  default: []
property :master, String
property :metric, String
property :mtu, String
property :network, String
property :nmstate, [true, false], default: lazy { default_nmstate }
property :nm_controlled, String, default: lazy { default_nm_controlled }
property :onboot, String, default: 'yes'
property :onparent, String
property :peerdns, String, default: 'no'
property :slave, String
property :type, String
property :userctl, String
property :vlan, String

deprecated_property_alias 'target', 'ipv4addr', 'target property has been deprecated in favor of ipv4addr'

action :add do
  validate_addresses
  nmstate_validate
  nmstate_prereqs

  package 'network-scripts' if node['platform_version'].to_i == 8

  # Disable deprecation warnings as we know these will go away in RHEL9+
  file '/etc/sysconfig/disable-deprecation-warnings' if node['platform_version'].to_i == 8

  if new_resource.nmstate
    # Locals, not method calls inside the blocks: Chef's method_missing
    # forwards with *args, turning keywords into a positional Hash on Ruby 3.
    config = nmstate_config
    apply = nmstate_apply_cmd
    vars = nmstate_vars(enabled: true, state: nmstate_state, routes: true)

    # Declared ahead of the template so the :immediately notification always
    # resolves.
    execute apply do
      action :nothing
    end

    template config do
      source 'nmstate.yml.erb'
      cookbook 'osl-resources'
      mode '0640'
      variables vars
      notifies :run, "execute[#{apply}]", :immediately
    end

    # Level-triggered repair: the notification above only fires on config
    # change, so a down interface with correct config is never brought up.
    execute "bring up #{new_resource.device}" do
      command apply
      not_if { osl_netns_link_admin_up?(new_resource.device) }
    end if nmstate_state == 'up'
  else
    config = ifcfg_config
    vars = ifcfg_vars

    execute "ifup #{new_resource.device}" do
      command ifup_cmd
      action :nothing
    end

    template config do
      source 'ifcfg.conf.erb'
      cookbook 'osl-resources'
      mode '0640'
      variables vars
      notifies :run, "execute[ifup #{new_resource.device}]", :immediately
    end

    execute "bring up #{new_resource.device}" do
      command ifup_cmd
      not_if { osl_netns_link_admin_up?(new_resource.device) }
    end if new_resource.onboot == 'yes'
  end
end

action :delete do
  nmstate_prereqs

  if new_resource.nmstate
    config = nmstate_config
    apply = nmstate_apply_cmd
    vars = nmstate_vars(enabled: false, state: 'absent', routes: false)

    execute apply do
      action :nothing
    end

    template config do
      source 'nmstate.yml.erb'
      cookbook 'osl-resources'
      mode '0640'
      variables vars
      notifies :run, "execute[#{apply}]", :immediately
    end
  else
    # ifdown dispatches on TYPE, so tear down before writing the stub or
    # bridges and bonds survive. The guard also covers an absent interface.
    config = ifcfg_config

    execute "ifdown #{new_resource.device}" do
      only_if { ::File.exist?(config) }
      only_if { osl_netns_link_admin_up?(new_resource.device) }
    end

    file config do
      content <<~EOF
        # ifcfg config file written by Chef
        DEVICE=#{new_resource.device}
        ONBOOT=no
        TYPE=none
      EOF
    end
  end
end

action :enable do
  nmstate_prereqs

  if new_resource.nmstate
    config = nmstate_config

    execute nmstate_apply_cmd do
      only_if { ::File.exist?(config) }
      not_if { osl_netns_link_admin_up?(new_resource.device) } unless new_resource.force
    end
  else
    execute "ifup #{new_resource.device}" do
      command ifup_cmd
      not_if { osl_netns_link_admin_up?(new_resource.device) } unless new_resource.force
    end
  end
end

action :disable do
  nmstate_prereqs

  if new_resource.nmstate
    config = nmstate_config
    vars = nmstate_vars(enabled: false, state: 'down', routes: false)

    template config do
      source 'nmstate.yml.erb'
      cookbook 'osl-resources'
      mode '0640'
      variables vars
    end

    execute nmstate_apply_cmd do
      only_if { osl_netns_link_admin_up?(new_resource.device) } unless new_resource.force
    end
  else
    execute "ifdown #{new_resource.device}" do
      only_if { osl_netns_link_admin_up?(new_resource.device) } unless new_resource.force
    end
  end
end

action_class do
  def nmstate_config
    "/etc/nmstate/#{new_resource.device}.yml"
  end

  def ifcfg_config
    "/etc/sysconfig/network-scripts/ifcfg-#{new_resource.device}"
  end

  def nmstate_apply_cmd
    "#{nmstatectl_cmd} #{nmstate_config}"
  end

  # ifup on an already-active NetworkManager connection exits 0 without
  # raising the admin flag, so it cannot repair an active-but-down device.
  def ifup_cmd
    "ifup #{new_resource.device} && ip link set dev #{new_resource.device} up"
  end

  # Every action needs these, not just :add: a delete-only recipe on a fresh
  # host has no /etc/nmstate and no nmstatectl.
  def nmstate_prereqs
    return unless new_resource.nmstate

    package 'nmstate'
    directory '/etc/nmstate'
  end

  # Resolved once and reused, so a bare IPv6 address warns once per converge.
  def nmstate_ipv4addrs
    return @nmstate_ipv4addrs if defined?(@nmstate_ipv4addrs)
    @nmstate_ipv4addrs = nmstate_ipaddrs(new_resource.ipv4addr)
  end

  def nmstate_ipv6addrs
    return @nmstate_ipv6addrs if defined?(@nmstate_ipv6addrs)
    @nmstate_ipv6addrs = nmstate_ipaddrs(Array(new_resource.ipv6addr) + Array(new_resource.ipv6addrsec))
  end

  # Both paths: a missing prefix is a silent /32 on nmstate and a classful
  # guess on ifcfg. :add only -- see nmstate_vars for why teardown must not.
  def validate_addresses
    nmstate_ipv4addrs
    nmstate_ipv6addrs
  end

  # Reject what nmstate cannot apply; warn about what it ignores.
  def nmstate_validate
    return unless new_resource.nmstate

    if (new_resource.type == 'vlan' || new_resource.vlan == 'yes') && nmstate_vlan_id.nil?
      raise "osl_ifconfig[#{new_resource.device}]: cannot derive a VLAN id from the device name. " \
            'Name the interface <parent>.<vlan-id>.'
    end

    opts = nmstate_bonding_opts.to_h
    if new_resource.type == 'bond' && opts.empty?
      raise "osl_ifconfig[#{new_resource.device}]: type 'bond' requires bonding_opts, at minimum mode=..."
    end

    if !opts.empty? && opts[:mode].nil?
      raise "osl_ifconfig[#{new_resource.device}]: bonding_opts must include mode=..."
    end

    if new_resource.bootproto == 'dhcp'
      Chef::Log.warn("osl_ifconfig[#{new_resource.device}]: bootproto 'dhcp' is ignored on the nmstate path")
    end

    if new_resource.ethtool_opts
      Chef::Log.warn("osl_ifconfig[#{new_resource.device}]: ethtool_opts is ignored on the nmstate path")
    end

    # The paths fail in opposite directions: ifcfg HWADDR= matches, so a stale
    # value leaves the interface down, while nmstate mac-address: sets, so a
    # stale value is pushed onto the NIC.
    if new_resource.hwaddr
      Chef::Log.warn(
        "osl_ifconfig[#{new_resource.device}]: hwaddr sets the interface MAC on the nmstate path, " \
        'where ifcfg HWADDR= only matches it. Remove it unless you mean to change the MAC.'
      )
    end
  end

  # One builder for all three actions; as three hand-maintained hashes they
  # had already drifted, crashing the template on any bond teardown.
  def nmstate_vars(enabled:, state:, routes:)
    # Teardown renders `enabled: false` with no addresses, so resolving them
    # only blocked the actions that would clean up the offending config.
    ipv4 = enabled ? nmstate_ipv4addrs : []
    ipv6 = enabled ? nmstate_ipv6addrs : []

    {
      bonding_opts: nmstate_bonding_opts,
      bond_ports: new_resource.bond_ports,
      bridge_options: new_resource.bridge_options,
      bridge_ports: new_resource.bridge_ports,
      controller: nmstate_controller,
      controller_bridge: new_resource.bridge,
      delay: new_resource.delay,
      device: new_resource.device,
      enabled: enabled,
      gateway: new_resource.gateway,
      interface: new_resource.device,
      ipv4addresses: ipv4,
      ipv6addr: ipv6,
      ipv6_autoconf: nmstate_ipv6_autoconf,
      ipv6_defaultgw: nmstate_gateway_addr(new_resource.ipv6_defaultgw),
      ipv6_dhcp: nmstate_ipv6_dhcp,
      ipv6_enabled: enabled && nmstate_ipv6_enabled?,
      mac_address: new_resource.hwaddr,
      metric: new_resource.metric,
      mtu: new_resource.mtu,
      routes: routes && new_resource.defroute != 'no',
      state: state,
      type: new_resource.type,
      vlan: new_resource.vlan,
      vlan_device: nmstate_vlan_device,
      vlan_id: nmstate_vlan_id,
    }
  end

  def ifcfg_vars
    {
      bcast: new_resource.bcast,
      bonding_opts: new_resource.bonding_opts,
      bootproto: new_resource.bootproto,
      bridge: new_resource.bridge,
      defroute: new_resource.defroute,
      delay: new_resource.delay,
      device: new_resource.device,
      ethtool_opts: new_resource.ethtool_opts,
      gateway: new_resource.gateway,
      hwaddr: new_resource.hwaddr,
      ipv4addr: new_resource.ipv4addr,
      ipv6addr: new_resource.ipv6addr,
      ipv6addrsec: new_resource.ipv6addrsec,
      ipv6_autoconf: new_resource.ipv6_autoconf,
      ipv6_defaultgw: nmstate_gateway_addr(new_resource.ipv6_defaultgw),
      ipv6init: new_resource.ipv6init,
      mask: new_resource.mask,
      master: new_resource.master,
      metric: new_resource.metric,
      mtu: new_resource.mtu,
      network: new_resource.network,
      nm_controlled: new_resource.nm_controlled,
      onboot: new_resource.onboot,
      onparent: new_resource.onparent,
      peerdns: new_resource.peerdns,
      slave: new_resource.slave,
      type: ifconfig_type,
      userctl: new_resource.userctl,
      vlan: new_resource.vlan,
    }
  end
end
