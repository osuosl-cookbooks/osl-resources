resource_name :osl_anubis
provides :osl_anubis
default_action :create
unified_mode true

property :bind_network, String, default: 'unix'
property :bind, String, default: lazy { "/run/anubis/#{name}.sock" }
property :cookie_domain, String
property :cookie_expiration_time, String, default: '168h'
property :cookie_partitioned, [true, false], default: false
property :difficulty, Integer, default: 4
property :metrics_bind, String, default: ':9090'
property :policy_fname, String
property :redirect_domains, String
property :serve_robots_txt, [true, false], default: false
property :target, String
property :webmaster_email, String

action :create do
  include_recipe 'yum-osuosl'

  package 'anubis'

  directory '/run/anubis'

  template "/etc/anubis/#{new_resource.name}.env" do
    cookbook 'osl-resources'
    source 'anubis.env.erb'
    variables(
      bind_network: new_resource.bind_network,
      bind: new_resource.bind,
      cookie_domain: new_resource.cookie_domain,
      cookie_expiration_time: new_resource.cookie_expiration_time,
      cookie_partitioned: new_resource.cookie_partitioned.to_s,
      difficulty: new_resource.difficulty,
      metrics_bind: new_resource.metrics_bind,
      policy_fname: new_resource.policy_fname,
      redirect_domains: new_resource.redirect_domains,
      serve_robots_txt: new_resource.serve_robots_txt.to_s,
      target: new_resource.target,
      webmaster_email: new_resource.webmaster_email
    )
    notifies :restart, "service[anubis@#{new_resource.name}.service]"
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
