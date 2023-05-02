require 'spec_helper'

describe 'osl_packagecloud_repo' do
  recipe do
    osl_packagecloud_repo 'varnishcache/varnish60lts'

    osl_packagecloud_repo 'varnishcache/varnish40' do
      action :remove
    end
  end

  context 'almalinux' do
    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_packagecloud_repo

    it do
      is_expected.to create_yum_repository('varnishcache_varnish60lts')
        .with(
          description: 'varnishcache_varnish60lts',
          baseurl: 'https://packagecloud.io/varnishcache/varnish60lts/el/$releasever/$basearch',
          repo_gpgcheck: true,
          gpgcheck: false,
          gpgkey: 'https://packagecloud.io/varnishcache/varnish60lts/gpgkey'
        )
    end
    it do
      is_expected.to remove_yum_repository('varnishcache_varnish40')
    end
  end

  context 'debian' do
    platform 'debian'
    cached(:subject) { chef_run }
    step_into :osl_packagecloud_repo

    it do
      is_expected.to add_apt_repository('varnishcache_varnish60lts')
        .with(
          uri: 'https://packagecloud.io/varnishcache/varnish60lts/debian',
          key: %w(https://packagecloud.io/varnishcache/varnish60lts/gpgkey),
          components: %w(main)
        )
    end
    it do
      is_expected.to remove_apt_repository('varnishcache_varnish40')
    end
  end
end
