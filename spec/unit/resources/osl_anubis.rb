require 'spec_helper'

describe 'osl_anubis' do
  recipe do
    osl_anubis 'default'
  end

  context 'almalinux' do
    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    it { is_expected.to include_recipe 'yum-osuosl' }
    it { is_expected.to install_package 'anubis' }
    it { is_expected.to create_directory '/run/anubis' }

    it do
      is_expected.to create_template('/etc/anubis/default.env').with(
        cookbook: 'osl-resources',
        source: 'anubis.env.erb',
        variables: {
          bind_network: 'unix',
          bind: '/run/anubis/default.sock',
          cookie_domain: nil,
          cookie_expiration_time: '168h',
          cookie_partitioned: 'false',
          difficulty: 4,
          metrics_bind: ':9090',
          policy_fname: nil,
          redirect_domains: nil,
          serve_robots_txt: 'false',
          target: nil,
          webmaster_email: nil,
        }
      )
    end

    it do
      expect(chef_run.template('/etc/anubis/default.env')).to notify('service[anubis@default.service]').to(:restart)
    end

    it { is_expected.to enable_service 'anubis@default.service' }
    it { is_expected.to start_service 'anubis@default.service' }
  end
end
