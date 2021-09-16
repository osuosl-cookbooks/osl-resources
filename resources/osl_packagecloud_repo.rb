resource_name :osl_packagecloud_repo
provides :osl_packagecloud_repo
unified_mode true

default_action :add

property :repository, String, name_property: true
property :base_url, String, default: 'https://packagecloud.io'

action :add do
  case node['platform_family']
  when 'rhel'
    yum_repository repo_name do
      description repo_name
      baseurl "#{new_resource.base_url}/#{new_resource.repository}/el/$releasever/$basearch"
      repo_gpgcheck true
      gpgcheck false
      gpgkey "#{new_resource.base_url}/#{new_resource.repository}/gpgkey"
    end
  when 'debian'
    apt_repository repo_name do
      uri "#{new_resource.base_url}/#{new_resource.repository}/debian"
      key "#{new_resource.base_url}/#{new_resource.repository}/gpgkey"
      components %w(main)
    end
  end
end

action :remove do
  case node['platform_family']
  when 'rhel'
    yum_repository repo_name do
      action :remove
    end
  when 'debian'
    apt_repository repo_name do
      action :remove
    end
  end
end

action_class do
  def repo_name
    new_resource.repository.gsub(/[^0-9A-z.\-]/, '_')
  end
end
