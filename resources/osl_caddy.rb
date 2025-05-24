resource_name :osl_caddy
provides :osl_caddy
default_action :install
unified_mode true

property :global_options, Array, default: []

action :install do
  yum_repository 'caddy' do
    description 'Copr repo for caddy owned by @caddy'
    baseurl "https://download.copr.fedorainfracloud.org/results/@caddy/caddy/epel-#{node['platform_version'].to_i}-$basearch/"
    gpgkey 'https://download.copr.fedorainfracloud.org/results/@caddy/caddy/pubkey.gpg'
  end

  package 'caddy'

  directory '/etc/caddy/sites'

  template '/etc/caddy/Caddyfile' do
    cookbook 'osl-resources'
    source 'Caddyfile.erb'
    variables(
      kitchen: kitchen?,
      global_options: new_resource.global_options
    )
    notifies :reload, 'service[caddy]'
  end

  service 'caddy' do
    action [:enable, :start]
  end
end

action :reload do
  service 'caddy' do
    action :reload
  end
end
