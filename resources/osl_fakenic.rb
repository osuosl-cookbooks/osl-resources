resource_name :osl_fakenic
provides :osl_fakenic
unified_mode true

default_action :create

property :interface, String, name_property: true
property :ip4, [String, Array], coerce: proc { |v| v.nil? ? nil : Array(v) }
property :ip6, [String, Array], coerce: proc { |v| v.nil? ? nil : Array(v) }
property :mac_address, String
property :multicast, [true, false], default: false

action :create do
  package 'network-scripts' if platform_family?('rhel') && node['platform_version'].to_i == 8

  kernel_module 'dummy'

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
end

action :delete do
  package 'network-scripts' if platform_family?('rhel') && node['platform_version'].to_i == 8

  kernel_module 'dummy'

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
