resource_name :osl_hugo
provides :osl_hugo
unified_mode true

default_action :install

property :version, String, default: '0'

action :install do
  package 'tar'

  hugo_version = osl_github_latest_version('gohugoio/hugo', new_resource.version)

  ark 'hugo' do
    url "https://github.com/gohugoio/hugo/releases/download/v#{hugo_version}/hugo_#{hugo_version}_Linux-64bit.tar.gz"
    prefix_root '/opt'
    prefix_home '/opt'
    has_binaries %w(hugo)
    strip_components 0
    version hugo_version
  end
end
