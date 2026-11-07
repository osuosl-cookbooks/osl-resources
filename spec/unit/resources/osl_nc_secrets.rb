require 'spec_helper'

describe 'osl_nc_secrets' do
  recipe do
    osl_nc_secrets 'default'
  end

  context 'almalinux' do
    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_nc_secrets

    github_releases = [
      { tag_name: 'v3.0.6', name: 'v3.0.6' },
      { tag_name: 'v3.0.5', name: 'v3.0.5' },
      { tag_name: 'v1.5.4', name: nil },
    ]

    before do
      allow(Net::HTTP).to receive(:get).and_return(github_releases.to_json)
    end

    it { is_expected.to install_package 'tar' }
    it do
      is_expected.to install_ark('nc-secrets').with(
        url: 'https://github.com/theCalcaholic/nextcloud-secrets/releases/download/v3.0.6/nc-secrets-cli.tar.gz',
        prefix_root: '/opt',
        prefix_home: '/opt',
        has_binaries: %w(nc-secrets),
        strip_components: 0,
        version: '3.0.6'
      )
    end
  end
end
