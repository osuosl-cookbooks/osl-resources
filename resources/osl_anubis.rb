resource_name :osl_anubis
provides :osl_anubis
default_action :create
unified_mode true

property :import_bots, Array, default: lazy { osl_anubis_default_bots }
property :custom_bots, Array
property :extra_config, Hash
property :extra_env, Hash
property :bind_network, String, default: 'tcp'
property :bind, String, default: '127.0.0.1:8932'
property :cookie_domain, String
property :cookie_expiration_time, String, default: '168h'
# Anubis enables the partitioned (CHIPS) flag by default as of v1.27.0
property :cookie_partitioned, [true, false], default: true
property :default_challenge, Hash, default: { 'algorithm' => 'fast', 'difficulty' => 4 }
# Set this only when several hosts share a load balancer and so need the same
# key; left unset, one is generated into ed25519_private_key_file on first run
property :ed25519_private_key_hex, String, sensitive: true
property :ed25519_private_key_file, String, default: lazy { "/etc/anubis/#{name}.key" }
property :metrics_bind, String, default: ':9090'
property :policy_fname, String, default: lazy { "/etc/anubis/botPolicies-#{name}.yaml" }
property :redirect_domains, String
property :serve_robots_txt, [true, false], default: false
property :target, String
property :webmaster_email, String

action :create do
  # Anubis warns about this itself, but only in its own log
  unless new_resource.redirect_domains
    Chef::Log.warn(
      "osl_anubis[#{new_resource.name}]: redirect_domains is not set, anubis will redirect to any " \
      'domain. Set it to the domains this instance serves.'
    )
  end

  include_recipe 'yum-osuosl'

  package 'anubis'

  # Persisted so a generated key survives restarts, keeping already-issued
  # cookies valid. An explicit key wins, so a load-balanced pair stays in sync.
  key = new_resource.ed25519_private_key_hex || osl_anubis_key(new_resource.ed25519_private_key_file)

  file new_resource.ed25519_private_key_file do
    content key
    owner 'root'
    group 'root'
    mode '0600'
    sensitive true
    notifies :restart, "service[anubis@#{new_resource.name}.service]"
  end

  # The key is handed over in the env file rather than by path: the unit runs
  # with DynamicUser=yes, so anubis cannot read a root-owned key file itself,
  # while systemd reads EnvironmentFile as root before dropping privileges.
  template "/etc/anubis/#{new_resource.name}.env" do
    cookbook 'osl-resources'
    source 'anubis.env.erb'
    owner 'root'
    group 'root'
    mode '0600'
    sensitive true
    variables(
      bind_network: new_resource.bind_network,
      bind: new_resource.bind,
      cookie_domain: new_resource.cookie_domain,
      cookie_expiration_time: new_resource.cookie_expiration_time,
      cookie_partitioned: new_resource.cookie_partitioned.to_s,
      ed25519_private_key_hex: key,
      extra_env: new_resource.extra_env,
      metrics_bind: new_resource.metrics_bind,
      policy_fname: new_resource.policy_fname,
      redirect_domains: new_resource.redirect_domains,
      serve_robots_txt: new_resource.serve_robots_txt.to_s,
      target: new_resource.target,
      webmaster_email: new_resource.webmaster_email
    )
    notifies :restart, "service[anubis@#{new_resource.name}.service]"
  end

  template "/etc/anubis/botPolicies-#{new_resource.name}.yaml" do
    cookbook 'osl-resources'
    source 'anubis-botPolicies.yaml.erb'
    variables(
      import_bots: new_resource.import_bots,
      custom_bots: new_resource.custom_bots,
      default_challenge: new_resource.default_challenge,
      extra_config: new_resource.extra_config
    )
    notifies :restart, "service[anubis@#{new_resource.name}.service]"
  end

  # anubis has no way to disable the metrics listener, so open it to OSL only
  osl_firewall_port "anubis-metrics-#{new_resource.name}" do
    ports [new_resource.metrics_bind.split(':').last]
    osl_only true
    action :accept
  end

  service "anubis@#{new_resource.name}.service" do
    action [:enable, :start]
  end
end

action :restart do
  service "anubis@#{new_resource.name}.service" do
    action :restart
  end
end
