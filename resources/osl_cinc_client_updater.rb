resource_name :osl_cinc_client_updater
provides :osl_cinc_client_updater
unified_mode true

default_action :update

property :version, String, name_property: true
property :channel, String, default: 'stable'
property :rubygems_url, String, default: 'https://rubygems.cinc.sh'
property :install_path, String, default: '/opt/cinc'
property :install_timeout, Integer, default: 600
property :post_install_action, String, equal_to: %w(kill exec), default: 'kill'
property :exec_command, String, default: lazy { $PROGRAM_NAME.split(' ').first }
property :exec_args, Array, default: lazy { ARGV }

action :update do
  backup_path = "#{new_resource.install_path}.upgrade"
  script_path = ::File.join(Chef::Config[:file_cache_path], 'cinc-client-install.sh')

  # The Cinc fork of mixlib-install (>= 4.1.2) serves the highest package iteration
  begin
    chef_gem 'mixlib-install' do
      version '>= 4.1.2'
      clear_sources true
      source new_resource.rubygems_url
    end
    info = osl_cinc_client_artifact(new_resource.version, new_resource.channel)
  rescue => e
    Chef::Log.warn("Unable to install mixlib-install from #{new_resource.rubygems_url}: #{e}")
  end

  current = node['chef_packages']['chef']['version']

  if info.nil?
    Chef::Log.warn("Unable to look up Cinc Client #{new_resource.version}, skipping the Cinc Client update")
  elsif osl_cinc_client_update_needed?(
    current,
    info['version'],
    osl_cinc_client_installed_iteration,
    osl_cinc_client_iteration(info['url'], info['version'])
  )
    converge_by "upgrade Cinc Client #{current} to #{::File.basename(info['url'])}" do
      FileUtils.rm_rf backup_path
      FileUtils.mv new_resource.install_path, backup_path

      begin
        ::File.write(script_path, info['install_command'], perm: 0o700)
        shell_out!('/bin/sh', script_path, timeout: new_resource.install_timeout)
        installed = shell_out!("#{new_resource.install_path}/bin/cinc-client", '--version').stdout
        raise "#{info['version']} is not the installed version: #{installed}" unless installed.include?(info['version'])
      rescue => e
        FileUtils.rm_rf new_resource.install_path
        FileUtils.mv backup_path, new_resource.install_path
        raise "Cinc Client update failed, restored #{new_resource.install_path}: #{e}"
      ensure
        FileUtils.rm_f script_path
      end
    end

    converge_by 'take post install action' do
      osl_cinc_client_post_install(new_resource.post_install_action, new_resource.exec_command, new_resource.exec_args)
    end
  elsif ::File.exist?(backup_path)
    converge_by "remove #{backup_path} from the previous update" do
      FileUtils.rm_rf backup_path
    end
  end
end
