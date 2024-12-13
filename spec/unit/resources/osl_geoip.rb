require 'spec_helper'

describe 'osl_geoip' do
  recipe do
    osl_geoip 'default' do
      account_id 123456
      license_key 'fake-key'
    end
  end

  context 'almalinux' do
    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_geoip

    it { is_expected.to include_recipe 'yum-osuosl' }
    it { is_expected.to install_package 'geoipupdate' }

    it do
      is_expected.to create_template('/etc/GeoIP.conf').with(
        cookbook: 'osl-resources',
        sensitive: true,
        mode: '0640',
        variables: {
          account_id: 123456,
          license_key: 'fake-key',
          edition_ids: 'GeoLite2-ASN GeoLite2-City GeoLite2-Country',
        }
      )
    end

    it do
      is_expected.to create_cron_d('geoipupdate').with(
        predefined_value: '@weekly',
        command: '/usr/bin/geoipupdate > /dev/null'
      )
    end
  end
end
