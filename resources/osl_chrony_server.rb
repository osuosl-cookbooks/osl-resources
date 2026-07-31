resource_name :osl_chrony_server
provides :osl_chrony_server, platform_family: 'rhel'
unified_mode true

default_action :create

property :allowed_networks, Array, required: true
property :conf, Hash, default: lazy { chrony_server_default_conf }
property :enable_nts_server, [true, false], default: false
property :key, String, required: true, sensitive: true
property :key_id, Integer, default: 1
property :ntp_servers, Hash, required: true
property :nts_server_cert, String
property :nts_server_key, String
property :pools, Hash, default: { '2.pool.ntp.org' => 'iburst maxsources 4' }
property :servers, Hash,
         default: {
           'time.cloudflare.com' => 'iburst nts',
           'time.nist.gov' => 'iburst',
         }

action :create do
  # NTS-KE for clients is only ever served from an off-site server
  nts = new_resource.enable_nts_server && !osl_local_ipv4?

  osl_chrony new_resource.name do
    allowed_networks new_resource.allowed_networks
    conf new_resource.conf
    key new_resource.key
    key_id new_resource.key_id
    nts_server_cert new_resource.nts_server_cert if nts
    nts_server_key new_resource.nts_server_key if nts
    peers chrony_peers(new_resource.ntp_servers)
    pools new_resource.pools
    servers new_resource.servers
  end
end
