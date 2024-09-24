resource_name :osl_nfdump
provides :osl_nfdump
default_action :create
unified_mode true

property :cache_directory, String, default: lazy { "/var/cache/nfdump/#{name}" }
property :options, String, default: ''
property :port, Integer, default: 2055

action :create do
  include_recipe 'osl-repos::epel'

  package 'nfdump'

  directory "/var/cache/nfdump/#{new_resource.name}" do
    recursive true
  end

  systemd_unit "nfdump-#{new_resource.name}.service" do
    content <<~EOU
      [Unit]
      Description=netflow capture daemon, #{new_resource.name} instance
      After=network.target auditd.service

      [Service]
      Type=forking
      ExecStart=/usr/bin/nfcapd -D -P /run/nfcapd.#{new_resource.name}.pid -l #{new_resource.cache_directory} -p #{new_resource.port} #{new_resource.options}
      PIDFile=/run/nfcapd.#{new_resource.name}.pid
      KillMode=process
      Restart=no

      [Install]
      WantedBy=multi-user.target
    EOU
    action :create
  end

  service "nfdump-#{new_resource.name}.service" do
    action [:enable, :start]
    subscribes :restart, "systemd_unit[nfdump-#{new_resource.name}.service]"
  end
end
