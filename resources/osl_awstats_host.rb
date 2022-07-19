resource_name :osl_awstats_host
provides :osl_awstats_host
unified_mode true

default_action :create

property :site_domain, String
property :host_aliases, Array, default: []
property :log_file, String, default: '*.log'
property :only_files, Array, default: []
property :using_ftp_dir, [true, false], default: false
property :options, Hash, default: {}

action :create do
  directory '/etc/awstats'

  template "/etc/awstats/awstats.#{new_resource.name}.conf" do
    source 'awstats_host.conf.erb'
    variables(
      site_domain: new_resource.site_domain,
      host_aliases: new_resource.host_aliases,
      log_file: new_resource.log_file,
      only_files: new_resource.only_files,
      ftp: new_resource.using_ftp_dir,
      options: new_resource.options
    )
    action :create
  end
end

action :delete do
  template "/etc/awstats/awstats.#{new_resource.name}.conf" do
    action :delete
  end
end
