resource_name :osl_nc_secrets
provides :osl_nc_secrets
unified_mode true

default_action :install

property :version, String, default: '3'

action :install do
  package 'tar'

  nc_secrets_version = osl_github_latest_version('theCalcaholic/nextcloud-secrets', new_resource.version, 'tag_name')

  ark 'nc-secrets' do
    url "https://github.com/theCalcaholic/nextcloud-secrets/releases/download/v#{nc_secrets_version}/nc-secrets-cli.tar.gz"
    prefix_root '/opt'
    prefix_home '/opt'
    has_binaries %w(nc-secrets)
    strip_components 0
    version nc_secrets_version
  end
end
