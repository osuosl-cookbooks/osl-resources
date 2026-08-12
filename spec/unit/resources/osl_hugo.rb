require 'spec_helper'

describe 'osl_hugo' do
  recipe do
    osl_hugo 'default'
  end

  github_releases = [{ name: 'v0.135.0' }, { name: 'v0.130.0' }, { name: 'v0.125.0' }]

  before do
    allow(Net::HTTP).to receive(:get).and_return(github_releases.to_json)
  end

  shared_examples 'hugo ark' do
    it do
      is_expected.to install_ark('hugo').with(
        url: 'https://github.com/gohugoio/hugo/releases/download/v0.135.0/hugo_extended_0.135.0_Linux-64bit.tar.gz',
        prefix_root: '/opt',
        prefix_home: '/opt',
        has_binaries: %w(hugo),
        strip_components: 0,
        version: '0.135.0'
      )
    end
  end

  context 'almalinux' do
    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_hugo

    it { is_expected.to install_package %w(tar libstdc++) }
    it_behaves_like 'hugo ark'
  end

  context 'debian' do
    platform 'debian'
    cached(:subject) { chef_run }
    step_into :osl_hugo

    it { is_expected.to install_package %w(tar libstdc++6) }
    it_behaves_like 'hugo ark'
  end
end
