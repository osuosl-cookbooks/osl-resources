require 'spec_helper'

describe 'osl_hugo' do
  recipe do
    osl_hugo '1.20.4'
  end

  context 'almalinux' do
    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_hugo

    it do
      is_expected.to install_package('tar')
    end
    it do
      is_expected.to install_ark('hugo')
      .with(
          url 'https://github.com/gohugoio/hugo/releases/download/v1.20.4_Linux-64bit.tar.gz',
          has_binaries: 'hugo',
          prefix_root: '/opt',
          prefix_home: '/opt',
        )
    end
  end
end
