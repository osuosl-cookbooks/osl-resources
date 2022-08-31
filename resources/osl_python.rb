resource_name :osl_python
provides :osl_python
unified_mode true

default_action :install

action :install do
  if platform_family?('rhel') && node['platform_version'].to_i < 8
    include_recipe 'osl-repos::epel'
  end

  package 'install python packages' do
    package_name osl_python_packages
  end

  # Debian 11 does not ship with pip2
  if platform_family?('debian')
    get_pip = ::File.join(Chef::Config[:file_cache_path], 'get-pip.py')

    remote_file get_pip do
      source 'https://bootstrap.pypa.io/pip/2.7/get-pip.py'
      not_if { ::File.exist?('/usr/local/bin/pip2') }
    end

    execute "python2 #{get_pip}" do
      creates '/usr/local/bin/pip2'
    end

    link '/usr/bin/pip2' do
      to '/usr/local/bin/pip2'
    end
  end
end
