resource_name :osl_hpnssh
provides :osl_hpnssh, platform_family: 'rhel'
unified_mode true

default_action :install

property :port, Integer, default: 2222
property :extra_options, Array, default: []

action :install do
  osl_dnf_copr 'rapier1/hpnssh'

  package %w(hpnssh hpnssh-clients hpnssh-server)

  template '/etc/hpnssh/sshd_config' do
    cookbook 'osl-resources'
    source 'hpnsshd_config.erb'
    owner 'root'
    group 'root'
    mode '0600'
    variables(
      port: new_resource.port,
      extra_options: new_resource.extra_options
    )
    notifies :restart, 'service[hpnsshd]'
  end

  service 'hpnsshd' do
    action [:enable, :start]
  end
end
