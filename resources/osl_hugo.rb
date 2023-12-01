resource_name :osl_hugo
provides :osl_hugo
unified_mode true

default_action :install

property :version, String, name_property: true

action :install do
  package 'tar'

  ark 'hugo' do
    url "https://github.com/gohugoio/hugo/releases/download/v#{new_resource.version}/hugo_#{new_resource.version}_Linux-64bit.tar.gz"
    creates 'hugo'
    path '/usr/local/bin/'
    action :cherry_pick
  end
end
