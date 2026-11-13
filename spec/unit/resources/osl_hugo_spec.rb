require 'spec_helper'

describe 'osl_hugo' do
  hugo_releases = [
    { tag_name: 'v0.171.0', prerelease: true },
    { tag_name: 'v0.170.0' },
    { tag_name: 'v0.169.0' },
  ]
  sass_releases = [{ tag_name: '1.108.2' }, { tag_name: '1.107.1' }]

  before do
    allow(Net::HTTP).to receive(:get)
      .with(URI('https://api.github.com/repos/gohugoio/hugo/releases'))
      .and_return(hugo_releases.to_json)
    allow(Net::HTTP).to receive(:get)
      .with(URI('https://api.github.com/repos/sass/dart-sass/releases'))
      .and_return(sass_releases.to_json)
  end

  shared_examples 'dart-sass ark' do |sass_version|
    it do
      is_expected.to install_ark('dart-sass').with(
        url: "https://github.com/sass/dart-sass/releases/download/#{sass_version}/dart-sass-#{sass_version}-linux-x64.tar.gz",
        prefix_root: '/opt',
        prefix_home: '/opt',
        has_binaries: %w(sass),
        strip_components: 1,
        version: sass_version
      )
    end
  end

  %w(almalinux debian).each do |p|
    context p do
      platform p
      recipe do
        osl_hugo 'default'
      end
      cached(:subject) { chef_run }
      step_into :osl_hugo

      it { is_expected.to install_package p == 'debian' ? %w(tar libstdc++6) : %w(tar libstdc++) }
      it do
        is_expected.to install_ark('hugo').with(
          url: 'https://github.com/gohugoio/hugo/releases/download/v0.170.0/hugo_0.170.0_linux-amd64.tar.gz',
          prefix_root: '/opt',
          prefix_home: '/opt',
          has_binaries: %w(hugo),
          strip_components: 0,
          version: '0.170.0'
        )
      end
      it_behaves_like 'dart-sass ark', '1.108.2'
    end
  end

  context 'Hugo pinned below 0.170' do
    platform 'almalinux'
    recipe do
      osl_hugo 'default' do
        version '0.169'
      end
    end
    cached(:subject) { chef_run }
    step_into :osl_hugo

    it do
      is_expected.to install_ark('hugo').with(
        url: 'https://github.com/gohugoio/hugo/releases/download/v0.169.0/hugo_extended_0.169.0_Linux-64bit.tar.gz',
        version: '0.169.0'
      )
    end
  end

  context 'Dart Sass pinned' do
    platform 'almalinux'
    recipe do
      osl_hugo 'default' do
        dart_sass_version '1.107'
      end
    end
    cached(:subject) { chef_run }
    step_into :osl_hugo

    it_behaves_like 'dart-sass ark', '1.107.1'
  end

  context 'Hugo pin with no matching release' do
    platform 'almalinux'
    recipe do
      osl_hugo 'default' do
        version '0.99'
      end
    end
    cached(:subject) { chef_run }
    step_into :osl_hugo

    it { is_expected.to_not install_ark('hugo') }
    it_behaves_like 'dart-sass ark', '1.108.2'
  end

  context 'Dart Sass pin with no matching release' do
    platform 'almalinux'
    recipe do
      osl_hugo 'default' do
        dart_sass_version '2'
      end
    end
    step_into :osl_hugo

    it { expect { chef_run }.to raise_error(RuntimeError, /No Dart Sass release matches dart_sass_version 2/) }
  end
end
