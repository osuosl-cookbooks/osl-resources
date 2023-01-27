resource_name :osl_virtualbox
provides :osl_virtualbox
unified_mode true

default_action :install

property :version, String, name_property: true

action :install do
  yum_repository 'virtualbox' do
    baseurl 'http://download.virtualbox.org/virtualbox/rpm/el/$releasever/$basearch'
    gpgcheck true
    repo_gpgcheck true
    gpgkey 'https://www.virtualbox.org/download/oracle_vbox.asc'
  end if platform_family?('rhel')

  apt_repository 'virtualbox' do
    components %w(contrib)
    uri 'https://download.virtualbox.org/virtualbox/debian'
    # Work around constant upstream issues pulling gpg keys
    ignore_failure true
    key %w(
      https://www.virtualbox.org/download/oracle_vbox_2016.asc
      https://www.virtualbox.org/download/oracle_vbox.asc
    )
  end if platform_family?('debian')

  kernel_module 'kvm_amd' do
    action [:unload, :blacklist]
  end

  kernel_module 'kvm_intel' do
    action [:unload, :blacklist]
  end

  kernel_module 'kvm' do
    action [:unload, :blacklist]
  end

  build_essential 'osl_virtualbox'

  package virtualbox_packages

  package "#{virtualbox_package_name}-#{new_resource.version}"
end
