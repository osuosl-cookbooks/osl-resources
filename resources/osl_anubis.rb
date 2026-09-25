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
# Exact user agents to DENY after the imports, ahead of custom rules and thresholds;
# [] turns the rule off. An empty entry would deny every client without a User-Agent.
property :deny_user_agents, Array,
         default: lazy { osl_anubis_stale_browser_user_agents },
         callbacks: { 'entries must be non-empty strings' => ->(l) { l.all? { |ua| ua.is_a?(String) && !ua.strip.empty? } } }
# Set this only when several hosts share a load balancer and so need the same
# key; left unset, one is generated into ed25519_private_key_file on first run
property :ed25519_private_key_hex, String, sensitive: true
property :ed25519_private_key_file, String, default: lazy { "/etc/anubis/#{name}.key" }
# One INFO line per challenge decision is 4 GB/day on a busy instance, and the
# decisions we read are in prometheus as anubis_policy_results.
property :log_level, String, default: 'WARN'
# Soft limit for the Go runtime, half the host's RAM by default. Without one
# resident memory runs at about twice the live heap, which put lb1 into swap.
property :memory_limit, String, default: lazy { osl_anubis_memory_limit }
property :metrics_bind, String, default: ':9090'
property :policy_fname, String, default: lazy { "/etc/anubis/botPolicies-#{name}.yaml" }
property :redirect_domains, String
property :serve_robots_txt, [true, false], default: false
# The local valkey where the platform ships one, bbolt elsewhere. bbolt's single
# fsync'd writer stalled lb1 under a crawl; the in-memory store put it in swap.
property :store, Hash, default: lazy { valkey ? osl_anubis_valkey_store(valkey_port) : osl_anubis_default_store(name) }
property :target, String
# Run valkey@anubis and default the store to it. Every anubis instance on a host
# shares it, so they must all agree on its settings.
property :valkey, [true, false], default: lazy { osl_valkey_supported? }
# osl_valkey seeds its config once; bump this for a setting change to reach a node
property :valkey_config_version, Integer, default: 1
property :valkey_maxmemory, String, default: '2gb'
# 6380 is taken by a nextcloud valkey on proj-opf
property :valkey_port, Integer, default: 6390
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

  # A store in extra_config replaces the store property, as the policy does
  store = new_resource.extra_config.to_h['store'] || new_resource.store.to_h
  backend = store.to_h['backend']

  if new_resource.valkey && backend == 'valkey'
    # In memory, never on disk: `save ""` turns off RDB snapshots. Every key
    # anubis writes has a TTL, so eviction only starts if maxmemory fills.
    osl_valkey 'anubis' do
      instance true
      port new_resource.valkey_port
      bind '127.0.0.1'
      firewall false
      maxmemory new_resource.valkey_maxmemory
      maxmemory_policy 'allkeys-lru'
      save ''
      config_version new_resource.valkey_config_version
    end

    # Anubis pings its store once at startup and exits if valkey is not up yet
    osl_systemd_unit_drop_in 'after-valkey' do
      unit_name "anubis@#{new_resource.name}.service"
      content('Unit' => { 'After' => 'valkey@anubis.service', 'Wants' => 'valkey@anubis.service' })
    end
  end

  # Left behind when an instance moves off bbolt. Anubis keeps the old file open
  # until it restarts onto the new store, so the space comes back then.
  file osl_anubis_default_store(new_resource.name)['parameters']['path'] do
    action :delete
  end unless backend == 'bbolt'

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
      # An explicit value in extra_env still wins over either property
      extra_env: { 'GOMEMLIMIT' => new_resource.memory_limit,
                   'SLOG_LEVEL' => new_resource.log_level }.merge(new_resource.extra_env.to_h),
      metrics_bind: new_resource.metrics_bind,
      policy_fname: new_resource.policy_fname,
      redirect_domains: new_resource.redirect_domains,
      serve_robots_txt: new_resource.serve_robots_txt.to_s,
      target: new_resource.target,
      webmaster_email: new_resource.webmaster_email
    )
    notifies :restart, "service[anubis@#{new_resource.name}.service]"
  end

  template new_resource.policy_fname do
    cookbook 'osl-resources'
    source 'anubis-botPolicies.yaml.erb'
    # Converted to plain hashes: values coming from node attributes are Mashes,
    # which YAML.dump tags as !ruby/hash and anubis cannot parse.
    variables(
      import_bots: new_resource.import_bots,
      custom_bots: new_resource.custom_bots&.map(&:to_h),
      default_challenge: new_resource.default_challenge,
      deny_user_agent_regex: (osl_anubis_user_agent_regex(new_resource.deny_user_agents) unless new_resource.deny_user_agents.empty?),
      extra_config: new_resource.extra_config&.to_h,
      # A store given in extra_config keeps working and replaces the default
      store: new_resource.extra_config&.to_h&.key?('store') ? nil : new_resource.store.to_h
    )
    notifies :restart, "service[anubis@#{new_resource.name}.service]"
  end

  # Registered so the prometheus server discovers every anubis instance, no
  # matter which cookbook deployed it, without a per-node run-list change.
  node.default['osl-resources']['anubis'][new_resource.name] =
    new_resource.metrics_bind.split(':').last

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

# Reverses :create. The anubis package stays put: the unit is templated, so
# other instances on the same host may still be using it.
action :remove do
  service "anubis@#{new_resource.name}.service" do
    action [:stop, :disable]
  end

  [
    "/etc/anubis/#{new_resource.name}.env",
    new_resource.policy_fname,
    new_resource.ed25519_private_key_file,
  ].each do |f|
    file f do
      action :delete
    end
  end

  # valkey@anubis is shared, so it goes only with the host's last instance
  osl_valkey 'anubis' do
    instance true
    action :delete
    only_if { new_resource.valkey && osl_anubis_last_instance?(new_resource.name) }
  end

  # osl_firewall_port has no removal action, so the metrics port stays open;
  # it is osl_only and the listener is gone once the service is stopped.
end
