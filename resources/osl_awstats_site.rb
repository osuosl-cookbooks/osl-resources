resource_name :osl_awstats_site
provides :osl_awstats_site
unified_mode true

default_action :create

property :site_domain, String, name_property: true
property :host_aliases, Array, default: []
property :log_file, String, default: '*.log'
property :append_suffix, [true, false], default: false
property :log_suffix, String, default: '.log'
property :append_date, [true, false], default: false
property :date_format, String, default: '-%YYYY-2%MM-2%DD-2'
property :only_files, Array, default: []
property :vsftp_logs, [true, false], default: false
property :use_osl_mirror, [true, false], default: true
property :options, Hash, default: {}

action :create do
  directory '/etc/awstats'

  template "/etc/awstats/awstats.#{new_resource.name}.conf" do
    cookbook 'osl-resources'
    source 'awstats_site.conf.erb'
    filename = new_resource.log_file
    filename.concat(new_resource.date_format) if new_resource.append_date
    filename.concat(new_resource.log_suffix) if new_resource.append_suffix
    variables(
      site_domain: new_resource.site_domain,
      host_aliases: new_resource.host_aliases,
      log_file: filename,
      only_files: new_resource.only_files,
      vsftp: new_resource.vsftp_logs,
      osl_mirror: new_resource.use_osl_mirror,
      options: new_resource.options
    )
  end
end

action :delete do
  file "/etc/awstats/awstats.#{new_resource.name}.conf" do
    action :delete
  end
end
