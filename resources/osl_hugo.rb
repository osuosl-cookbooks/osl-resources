resource_name :osl_hugo
provides :osl_hugo
unified_mode true

default_action :install

property :version, String, default: '0'
property :dart_sass_version, String, default: '1'

action :install do
  package hugo_packages

  hugo_version = osl_github_latest_version('gohugoio/hugo', new_resource.version, 'tag_name')

  if hugo_version
    # Hugo 0.170 dropped LibSass and the extended build; older releases need the extended build for toCSS
    hugo_url =
      if Gem::Version.new(hugo_version) >= Gem::Version.new('0.170.0')
        "https://github.com/gohugoio/hugo/releases/download/v#{hugo_version}/hugo_#{hugo_version}_linux-amd64.tar.gz"
      else
        "https://github.com/gohugoio/hugo/releases/download/v#{hugo_version}/hugo_extended_#{hugo_version}_Linux-64bit.tar.gz"
      end

    begin
      ark 'hugo' do
        url hugo_url
        prefix_root '/opt'
        prefix_home '/opt'
        has_binaries %w(hugo)
        strip_components 0
        version hugo_version
      end
    rescue
      Chef::Log.warn("Error downloading hugo-#{hugo_version}, skipping for now")
    end
  else
    Chef::Log.warn("No Hugo release matches version #{new_resource.version}, skipping Hugo")
  end

  # Hugo compiles Sass only through an external Dart Sass binary on PATH
  dart_sass_version = osl_github_latest_version('sass/dart-sass', new_resource.dart_sass_version, 'tag_name')
  raise "No Dart Sass release matches dart_sass_version #{new_resource.dart_sass_version}" unless dart_sass_version

  ark 'dart-sass' do
    url "https://github.com/sass/dart-sass/releases/download/#{dart_sass_version}/dart-sass-#{dart_sass_version}-linux-x64.tar.gz"
    prefix_root '/opt'
    prefix_home '/opt'
    has_binaries %w(sass)
    version dart_sass_version
  end
end
