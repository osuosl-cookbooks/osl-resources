resource_name :osl_test_netns
provides :osl_test_netns
unified_mode true

default_action :create

property :netns_name, String, name_property: true
property :server_interface, String,
  default: lazy { "veth-srv-#{netns_name[0, 6]}" }
property :server_ip, String, required: %i(create)
property :client_interface, String,
  default: lazy { "veth-cli-#{netns_name[0, 6]}" }
property :client_ip, String, required: %i(create)
property :client_mac, String

action :create do
  ns = new_resource.netns_name
  srv = new_resource.server_interface
  cli = new_resource.client_interface
  srv_ip = new_resource.server_ip
  cli_ip = new_resource.client_ip
  cli_mac = new_resource.client_mac

  execute "create netns #{ns}" do
    command "ip netns add #{ns}"
    not_if { osl_netns_exists?(ns) }
  end

  execute "create veth pair #{srv} <-> #{cli}" do
    command "ip link add #{srv} type veth peer name #{cli}"
    not_if { osl_netns_link_exists?(srv) }
  end

  execute "move #{cli} to netns #{ns}" do
    command "ip link set #{cli} netns #{ns}"
    not_if { osl_netns_link_exists?(cli, netns: ns) }
  end

  execute "assign IP #{srv_ip} to #{srv}" do
    command "ip addr add #{srv_ip} dev #{srv}"
    not_if { osl_netns_link_has_addr?(srv, srv_ip) }
  end

  execute "bring #{srv} up" do
    command "ip link set #{srv} up"
    not_if { osl_netns_link_admin_up?(srv) }
  end

  if cli_mac
    execute "set MAC #{cli_mac} on #{cli} in netns #{ns}" do
      command "ip -n #{ns} link set #{cli} address #{cli_mac}"
      not_if { osl_netns_link_has_mac?(cli, cli_mac, netns: ns) }
    end
  end

  execute "assign IP #{cli_ip} to #{cli} in netns #{ns}" do
    command "ip -n #{ns} addr add #{cli_ip} dev #{cli}"
    not_if { osl_netns_link_has_addr?(cli, cli_ip, netns: ns) }
  end

  execute "bring #{cli} up in netns #{ns}" do
    command "ip -n #{ns} link set #{cli} up"
    not_if { osl_netns_link_admin_up?(cli, netns: ns) }
  end

  execute "bring lo up in netns #{ns}" do
    command "ip -n #{ns} link set lo up"
    not_if { osl_netns_link_admin_up?('lo', netns: ns) }
  end
end

action :delete do
  ns = new_resource.netns_name
  srv = new_resource.server_interface
  cli = new_resource.client_interface

  execute "bring #{cli} down in netns #{ns}" do
    command "ip -n #{ns} link set #{cli} down"
    only_if { osl_netns_exists?(ns) && osl_netns_link_exists?(cli, netns: ns) }
  end

  execute "move #{cli} back to host netns" do
    command "ip -n #{ns} link set #{cli} netns 1"
    only_if { osl_netns_exists?(ns) && osl_netns_link_exists?(cli, netns: ns) }
  end

  execute "delete veth #{srv}" do
    command "ip link delete #{srv}"
    only_if { osl_netns_link_exists?(srv) && osl_netns_link_is_type?(srv, 'veth') }
  end

  execute "delete netns #{ns}" do
    command "ip netns delete #{ns}"
    only_if { osl_netns_exists?(ns) }
  end
end
