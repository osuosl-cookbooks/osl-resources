resource_name :osl_pagefind
provides :osl_pagefind
unified_mode true

default_action :install

property :version, String, default: '1'

action :install do
  package 'tar'

  pagefind_version = osl_github_latest_version('Pagefind/pagefind', new_resource.version)

  ark 'pagefind' do
    url "https://github.com/Pagefind/pagefind/releases/download/v#{pagefind_version}/pagefind-v#{pagefind_version}-x86_64-unknown-linux-musl.tar.gz"
    prefix_root '/opt'
    prefix_home '/opt'
    has_binaries %w(pagefind)
    strip_components 0
    version pagefind_version
  end
end
