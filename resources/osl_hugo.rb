resource_name :osl_hugo
provides :osl_hugo
unified_mode true

default_action :install

property :version, String, name_property: true

action :install do
  package 'tar'

  ark 'hugo' do
    url "https://github.com/gohugoio/hugo/releases/download/v#{new_resource.version}/hugo_#{new_resource.version}_Linux-64bit.tar.gz"
    prefix_root '/opt'
    prefix_home '/opt'
    has_binaries [ 'hugo' ]
    strip_components 0
    version new_resource.version
    action :install
  end
end
