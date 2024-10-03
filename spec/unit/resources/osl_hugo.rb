require 'spec_helper'

describe 'osl_hugo' do
  recipe do
    osl_hugo 'default'
  end

  context 'almalinux' do
    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_hugo

    github_releases = [{ name: 'v0.135.0' }, { name: 'v0.130.0' }, { name: 'v0.125.0' }]

    before do
      allow(Net::HTTP).to receive(:get).and_return(github_releases.to_json)
    end

    it { is_expected.to install_package 'tar' }
    it do
      is_expected.to install_ark('hugo').with(
        url: 'https://github.com/gohugoio/hugo/releases/download/v0.135.0/hugo_0.135.0_Linux-64bit.tar.gz',
        prefix_root: '/opt',
        prefix_home: '/opt',
        has_binaries: %w(hugo),
        strip_components: 0,
        version: '0.135.0'
      )
    end
  end
end
