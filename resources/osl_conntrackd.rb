resource_name :osl_conntrackd
provides :osl_conntrackd
unified_mode true

default_action :create

property :interface, String, required: true
property :ipv4_address, String, name_property: true
property :ipv4_destination_address, String, required: true
property :address_ignore, Array, default: %w(127.0.0.1)

action :create do
  package 'conntrack-tools'

  template '/etc/conntrackd/conntrackd.conf' do
    source 'conntrackd.conf.erb'
    cookbook 'osl-resources'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      interface: new_resource.interface,
      ipv4_address: new_resource.ipv4_address,
      ipv4_destination_address: new_resource.ipv4_destination_address,
      address_ignore: new_resource.address_ignore
    )
    notifies :restart, 'service[conntrackd]'
  end

  remote_file '/etc/conntrackd/primary-backup.sh' do
    if node['platform_version'].to_i >= 8
      source 'file:///usr/share/doc/conntrack-tools/doc/sync/primary-backup.sh'
    else
      source 'file:///usr/share/doc/conntrack-tools-1.4.4/doc/sync/primary-backup.sh'
    end
    mode '0755'
  end

  service 'conntrackd' do
    action [:enable, :start]
  end
end
