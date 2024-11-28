resource_name :osl_opensearch
provides :osl_opensearch
default_action :create
unified_mode true

property :admin_dn, String, default: 'CN=admin'
property :ca, String, default: '/etc/opensearch/easy-rsa/pki/ca.crt'
property :cert_path, String, default: '/etc/opensearch/easy-rsa/pki/issued'
property :cluster_name, String, name_property: true
property :create_ca, [true, false], default: true
property :discovery_seed_hosts, Array, default: %w(127.0.0.1 [::1])
property :discovery_type, String, default: 'single-node'
property :initial_cluster_manager_nodes, Array, default: []
property :internal_users, Hash, default: {}, sensitive: true
property :key_path, String, default: '/etc/opensearch/easy-rsa/pki/private'
property :network_host, String, default: '0.0.0.0'
property :nodes_dn, String, default: 'CN=*.osuosl.org'
property :security_disabled, [true, false], default: false

action :create do
  include_recipe 'osl-repos::opensearch'
  include_recipe 'osl-repos::epel' if new_resource.create_ca

  package 'opensearch'
  package 'easy-rsa' if new_resource.create_ca

  secrets = osl_opensearch_secrets
  easy_rsa = '/etc/opensearch/easy-rsa/easyrsa --batch'

  directory '/etc/opensearch/easy-rsa' do
    user 'opensearch'
    group 'opensearch'
    mode '0750'
  end if new_resource.create_ca

  execute 'copy easy-rsa' do
    user 'opensearch'
    group 'opensearch'
    command 'cp -a /usr/share/easy-rsa/3/* /etc/opensearch/easy-rsa/'
    creates '/etc/opensearch/easy-rsa/easyrsa'
  end if new_resource.create_ca

  cookbook_file '/etc/opensearch/easy-rsa/x509-types/client' do
    owner 'opensearch'
    group 'opensearch'
    cookbook 'osl-resources'
    source 'x509-types-client'
  end if new_resource.create_ca

  cookbook_file '/etc/opensearch/easy-rsa/x509-types/server' do
    owner 'opensearch'
    group 'opensearch'
    cookbook 'osl-resources'
    source 'x509-types-server'
  end if new_resource.create_ca

  cookbook_file '/etc/opensearch/easy-rsa/x509-types/serverClient' do
    owner 'opensearch'
    group 'opensearch'
    cookbook 'osl-resources'
    source 'x509-types-server'
  end if new_resource.create_ca

  execute 'create vpn certificates' do
    user 'opensearch'
    group 'opensearch'
    cwd '/etc/opensearch/easy-rsa'
    command <<~EOC
      #{easy_rsa} init-pki
      #{easy_rsa} build-ca nopass
      #{easy_rsa} gen-crl
      #{easy_rsa} gen-dh
      #{easy_rsa} build-serverClient-full #{node['fqdn']} nopass
      #{easy_rsa} build-client-full admin nopass
    EOC
    creates "/etc/opensearch/easy-rsa/pki/issued/#{node['fqdn']}.crt"
    only_if { new_resource.create_ca }
  end

  template '/etc/opensearch/opensearch.yml' do
    owner 'opensearch'
    group 'opensearch'
    cookbook 'osl-resources'
    mode '0640'
    variables(
      admin_dn: new_resource.admin_dn,
      ca: new_resource.ca,
      cert_path: new_resource.cert_path,
      cluster_name: new_resource.cluster_name,
      discovery_seed_hosts: new_resource.discovery_seed_hosts.sort,
      discovery_type: new_resource.discovery_type,
      initial_cluster_manager_nodes: new_resource.initial_cluster_manager_nodes.sort,
      key_path: new_resource.key_path,
      network_host: new_resource.network_host,
      nodes_dn: new_resource.nodes_dn,
      security_disabled: new_resource.security_disabled
    )
    notifies :restart, 'service[opensearch]'
  end

  template '/etc/opensearch/opensearch-security/internal_users.yml' do
    owner 'opensearch'
    group 'opensearch'
    cookbook 'osl-resources'
    mode '0640'
    sensitive true
    variables(
      admin_hash: secrets['admin_hash']
    )
    notifies :restart, 'service[opensearch]'
  end

  service 'opensearch' do
    action [:enable, :start]
  end
end
