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
  package 'nmstate' if new_resource.nmstate
  package 'network-scripts' if node['platform_version'].to_i == 8
  package 'bridge-utils' unless node['platform_version'].to_i >= 8

  # Disable deprecation warnings as we know these will go away in RHEL9+
  file '/etc/sysconfig/disable-deprecation-warnings' if node['platform_version'].to_i == 8

  directory '/etc/nmstate' if new_resource.nmstate

  template "/etc/nmstate/#{new_resource.device}.yml" do
    source 'nmstate.yml.erb'
    cookbook 'osl-resources'
    mode '0640'
    variables(
      bonding_opts: nmstate_bonding_opts,
      bond_ports: new_resource.bond_ports,
      bridge: new_resource.bridge,
      bridge_ports: new_resource.bridge_ports,
      device: new_resource.device,
      enabled: true,
      ethtool_opts: new_resource.ethtool_opts,
      gateway: new_resource.gateway,
      interface: new_resource.device,
      ipv4addresses: nmstate_ipaddrs(new_resource.ipv4addr),
      ipv6addr: nmstate_ipaddrs(new_resource.ipv6addr),
      ipv6addrsec: nmstate_ipaddrs(new_resource.ipv6addrsec),
      ipv6_autoconf: nmstate_ipv6_autoconf,
      ipv6_defaultgw: nmstate_ipaddrs([new_resource.ipv6_defaultgw]),
      ipv6init: new_resource.ipv6init,
      mac_address: new_resource.hwaddr,
      mask: new_resource.mask,
      mtu: new_resource.mtu,
      state: nmstate_state,
      type: new_resource.type,
      vlan_device: nmstate_vlan_device,
      vlan_id: nmstate_vlan_id,
      vlan: new_resource.vlan
    )
    notifies :run, "execute[#{nmstatectl_cmd} /etc/nmstate/#{new_resource.device}.yml]", :immediately
  end if new_resource.nmstate

  template "/etc/sysconfig/network-scripts/ifcfg-#{new_resource.device}" do
    source 'ifcfg.conf.erb'
    cookbook 'osl-resources'
    mode '0640'
    variables(
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
      ipv6addr: new_resource.ipv6addr,
      ipv6addrsec: new_resource.ipv6addrsec,
      ipv6_autoconf: new_resource.ipv6_autoconf,
      ipv6_defaultgw: new_resource.ipv6_defaultgw,
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
      ipv4addr: new_resource.ipv4addr,
      type: ifconfig_type,
      userctl: new_resource.userctl,
      vlan: new_resource.vlan
    )
    notifies :run, "execute[ifup #{new_resource.device}]", :immediately
  end unless new_resource.nmstate

  execute "ifup #{new_resource.device}" do
    action :nothing
  end unless new_resource.nmstate

  execute "#{nmstatectl_cmd} /etc/nmstate/#{new_resource.device}.yml" do
    action :nothing
  end if new_resource.nmstate
end

action :delete do
  template "/etc/nmstate/#{new_resource.device}.yml" do
    source 'nmstate.yml.erb'
    cookbook 'osl-resources'
    mode '0640'
    variables(
      bonding_opts: nmstate_bonding_opts,
      bridge: new_resource.bridge,
      bridge_ports: new_resource.bridge_ports,
      device: new_resource.device,
      enabled: false,
      ethtool_opts: new_resource.ethtool_opts,
      gateway: new_resource.gateway,
      interface: new_resource.device,
      ipv4addresses: nmstate_ipaddrs(new_resource.ipv4addr),
      ipv6addr: nmstate_ipaddrs(new_resource.ipv6addr),
      ipv6addrsec: nmstate_ipaddrs(new_resource.ipv6addrsec),
      ipv6_autoconf: nmstate_ipv6_autoconf,
      ipv6_defaultgw: nmstate_ipaddrs([new_resource.ipv6_defaultgw]),
      ipv6init: new_resource.ipv6init,
      mac_address: new_resource.hwaddr,
      mask: new_resource.mask,
      mtu: new_resource.mtu,
      state: 'absent',
      type: new_resource.type,
      vlan_device: nmstate_vlan_device,
      vlan_id: nmstate_vlan_id,
      vlan: new_resource.vlan
    )
    notifies :run, "execute[#{nmstatectl_cmd} /etc/nmstate/#{new_resource.device}.yml]", :immediately
  end if new_resource.nmstate

  file "/etc/sysconfig/network-scripts/ifcfg-#{new_resource.device}" do
    content <<~EOF
      # ifcfg config file written by Chef
      DEVICE=#{new_resource.device}
      ONBOOT=no
      TYPE=none
    EOF
    notifies :run, "execute[ifdown #{new_resource.device}]", :immediately
  end unless new_resource.nmstate

  execute "ifdown #{new_resource.device}" do
    action :nothing
  end unless new_resource.nmstate

  execute "#{nmstatectl_cmd} /etc/nmstate/#{new_resource.device}.yml" do
    action :nothing
  end if new_resource.nmstate
end

action :enable do
  execute "ifup #{new_resource.device}" do
    not_if "ip link show dev #{new_resource.device} | grep 'UP'" unless new_resource.force
  end unless new_resource.nmstate

  execute "#{nmstatectl_cmd} /etc/nmstate/#{new_resource.device}.yml" do
    not_if "ip link show dev #{new_resource.device} | grep 'UP'" unless new_resource.force
  end if new_resource.nmstate
end

action :disable do
  execute "ifdown #{new_resource.device}" do
    not_if "ip link show dev #{new_resource.device} | grep 'DOWN'" unless new_resource.force
  end unless new_resource.nmstate

  template "/etc/nmstate/#{new_resource.device}.yml" do
    source 'nmstate.yml.erb'
    cookbook 'osl-resources'
    mode '0640'
    variables(
      bonding_opts: nmstate_bonding_opts,
      bridge: new_resource.bridge,
      bridge_ports: new_resource.bridge_ports,
      device: new_resource.device,
      enabled: false,
      ethtool_opts: new_resource.ethtool_opts,
      gateway: new_resource.gateway,
      interface: new_resource.device,
      ipv4addresses: nmstate_ipaddrs(new_resource.ipv4addr),
      ipv6addr: nmstate_ipaddrs(new_resource.ipv6addr),
      ipv6addrsec: nmstate_ipaddrs(new_resource.ipv6addrsec),
      ipv6_autoconf: nmstate_ipv6_autoconf,
      ipv6_defaultgw: nmstate_ipaddrs([new_resource.ipv6_defaultgw]),
      mac_address: new_resource.hwaddr,
      mask: new_resource.mask,
      mtu: new_resource.mtu,
      state: 'down',
      type: new_resource.type,
      vlan_device: nmstate_vlan_device,
      vlan_id: nmstate_vlan_id,
      vlan: new_resource.vlan
    )
    notifies :run, "execute[#{nmstatectl_cmd} /etc/nmstate/#{new_resource.device}.yml]", :immediately
  end if new_resource.nmstate

  execute "#{nmstatectl_cmd} /etc/nmstate/#{new_resource.device}.yml" do
    only_if "ip link show dev #{new_resource.device} | grep 'UP'" unless new_resource.force
  end if new_resource.nmstate
end
