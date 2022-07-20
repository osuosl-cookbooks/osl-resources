resource_name :osl_awstats_site
provides :osl_awstats_site
unified_mode true

default_action :create

property :site_domain, String, name_property: true
property :host_aliases, Array, default: []
property :log_file, String, default: '*.log'
property :only_files, Array, default: []
property :vsftp_logs, [true, false], default: false
property :options, Hash, default: {}

action :create do
  directory '/etc/awstats'

  template "/etc/awstats/awstats.#{new_resource.name}.conf" do
    cookbook 'osl-resources'
    source 'awstats_site.conf.erb'
    variables(
      site_domain: new_resource.site_domain,
      host_aliases: new_resource.host_aliases,
      log_file: new_resource.log_file,
      only_files: new_resource.only_files,
      vsftp: new_resource.vsftp_logs,
      options: new_resource.options
    )
  end
end

action :delete do
  file "/etc/awstats/awstats.#{new_resource.name}.conf" do
    action :delete
  end
end
