resource_name :osl_ifconfig
provides :osl_ifconfig
unified_mode true

default_action :add

provides :osl_ifconfig, platform_family: 'rhel'
property :bcast, String
property :bonding_opts, String
property :bootproto, String
property :bridge, String
property :defroute, String
property :delay, String
property :device, String, identity: true
property :ethtool_opts, String
property :force, [true, false], default: false
property :gateway, String
property :hwaddr, String
property :ipv6addr, String
property :ipv6addrsec, Array
property :ipv6_autoconf, String
property :ipv6_defaultgw, String
property :ipv6init, String
property :mask, String
property :master, String
property :metric, String
property :mtu, String
property :network, String
property :nm_controlled, String, default: lazy { default_nm_controlled }
property :onboot, String, default: 'yes'
property :onparent, String
property :peerdns, String, default: 'no'
property :slave, String
property :target, [String, Array], name_property: true
property :type, String
property :userctl, String
property :vlan, String

action :add do
  package 'network-scripts'

  # Disable deprecation warnings as we know these will go away in RHEL9+
  file '/etc/sysconfig/disable-deprecation-warnings'

  template "/etc/sysconfig/network-scripts/ifcfg-#{new_resource.device}" do
    source 'ifcfg.conf.erb'
    cookbook 'osl-resources'
    owner 'root'
    group 'root'
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
      target: new_resource.target,
      type: new_resource.type,
      userctl: new_resource.userctl,
      vlan: new_resource.vlan
    )
    notifies :run, "execute[ifup #{new_resource.device}]", :immediately
  end

  execute "ifup #{new_resource.device}" do
    action :nothing
  end
end

action :delete do
  file "/etc/sysconfig/network-scripts/ifcfg-#{new_resource.device}" do
    content <<~EOF
      # ifcfg config file written by Chef
      DEVICE=#{new_resource.device}
      ONBOOT=no
      TYPE=none
    EOF
    notifies :run, "execute[ifdown #{new_resource.device}]", :immediately
  end

  execute "ifdown #{new_resource.device}" do
    action :nothing
  end
end

action :enable do
  execute "ifup #{new_resource.device}" do
    not_if "ip link show dev #{new_resource.device} | grep 'UP'" unless new_resource.force
  end
end

action :disable do
  execute "ifdown #{new_resource.device}" do
    not_if "ip link show dev #{new_resource.device} | grep 'DOWN'" unless new_resource.force
  end
end
