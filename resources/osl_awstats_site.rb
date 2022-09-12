resource_name :osl_awstats_site
provides :osl_awstats_site
unified_mode true

default_action :create

property :log_file, String, default: '*'
property :log_ext, String, default: '.log'
property :append_date, [true, false], default: false
property :date_format, String, default: '-%YYYY-2%MM-2%DD-2'
property :vsftp_logs, [true, false], default: false
property :site_domain, [String, Array], name_property: true
property :host_aliases, [String, Array], default: ''
property :log_format, [String, Array], default: lazy { awstats_default_log_format }
property :only_files, [String, Array], default: []
property :use_osl_mirror, [true, false], default: false
property :options, Hash, default: {}

action :create do
  directory '/etc/awstats'

  template "/etc/awstats/awstats.#{new_resource.name}.conf" do
    cookbook 'osl-resources'
    source 'awstats_site.conf.erb'

    # Determine the log file parameter
    if new_resource.use_osl_mirror
      log_file = '/usr/share/awstats/tools/logresolvemerge.pl '
      dir_base = '/var/lib/awstats/logs/ftp-'

      filename = ''
      filename.concat('_ftp') if new_resource.vsftp_logs
      filename.concat('/')
      filename.concat(new_resource.log_file)
      filename.concat(new_resource.date_format) if new_resource.append_date
      filename.concat(new_resource.log_ext)

      mirrors = %w(
        osl
        chi
        nyc
      )

      log_file.concat(mirrors.map { |k| "#{dir_base}#{k}#{filename}" }.join(' '))
      log_file.concat(' |')
    else
      log_file = new_resource.log_file
      log_file.concat(new_resource.log_ext)
    end

    variables(
      log_file: log_file,
      site_domain: array_to_string(new_resource.site_domain),
      host_aliases: array_to_string(new_resource.host_aliases),
      log_format: array_to_string(new_resource.log_format),
      only_files: array_to_string(new_resource.only_files),
      options: new_resource.options
    )
  end
end

action :delete do
  file "/etc/awstats/awstats.#{new_resource.name}.conf" do
    action :delete
  end
end
