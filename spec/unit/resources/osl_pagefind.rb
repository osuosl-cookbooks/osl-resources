require 'spec_helper'

describe 'osl_pagefind' do
  recipe do
    osl_pagefind 'default'
  end

  context 'almalinux' do
    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_pagefind

    github_releases = [{ name: 'v1.1.1' }, { name: 'v1.1.0' }, { name: 'v1.0.0' }]

    before do
      allow(Net::HTTP).to receive(:get).and_return(github_releases.to_json)
    end

    it { is_expected.to install_package 'tar' }
    it do
      is_expected.to install_ark('pagefind').with(
        url: 'https://github.com/CloudCannon/pagefind/releases/download/v1.1.1/pagefind-v1.1.1-x86_64-unknown-linux-musl.tar.gz',
        prefix_root: '/opt',
        prefix_home: '/opt',
        has_binaries: %w(pagefind),
        strip_components: 0,
        version: '1.1.1'
      )
    end
  end
end
