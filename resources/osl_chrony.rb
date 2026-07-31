resource_name :osl_chrony
provides :osl_chrony
unified_mode true

default_action :create

property :allowed_networks, Array, default: []
property :conf, Hash, default: lazy { chrony_default_conf }
property :key, String, sensitive: true
property :key_id, Integer, default: 1
property :keyfile, String, default: lazy { chrony_keyfile }
property :nts_server_cert, String
property :nts_server_key, String
property :peers, Array, default: []
property :pools, Hash, default: lazy { chrony_default_pools }
property :servers, Hash, default: {}

action :create do
  # chrony replaces both ntpd and systemd-timesyncd; make sure neither is
  # fighting over the clock
  service 'ntp' do
    service_name platform_family?('rhel') ? 'ntpd' : 'ntp'
    action [:disable, :stop]
  end

  service 'systemd-timesyncd' do
    action [:disable, :stop]
  end

  package 'chrony'

  service 'chrony' do
    service_name chrony_service
    action [:enable, :start]
  end

  template chrony_conf_path do
    cookbook 'osl-resources'
    source 'chrony.conf.erb'
    variables(
      allowed_networks: new_resource.allowed_networks,
      conf: new_resource.key ? new_resource.conf.merge('keyfile' => new_resource.keyfile) : new_resource.conf,
      key_id: new_resource.key_id,
      nts_server_cert: new_resource.nts_server_cert,
      nts_server_key: new_resource.nts_server_key,
      peers: new_resource.peers,
      pools: new_resource.pools,
      servers: new_resource.servers
    )
    notifies :restart, 'service[chrony]'
  end

  template new_resource.keyfile do
    cookbook 'osl-resources'
    source 'chrony.keys.erb'
    owner 'root'
    group chrony_group
    mode '0640'
    sensitive true
    variables(
      key: new_resource.key,
      key_id: new_resource.key_id
    )
    notifies :restart, 'service[chrony]'
  end if new_resource.key
end
