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
          bind_network: 'tcp',
          bind: '127.0.0.1:8932',
          cookie_domain: nil,
          cookie_expiration_time: '168h',
          cookie_partitioned: 'false',
          difficulty: 4,
          metrics_bind: ':9090',
          policy_fname: '/etc/anubis/botPolicies-default.yaml',
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

    it do
      is_expected.to create_template('/etc/anubis/botPolicies-default.yaml').with(
        cookbook: 'osl-resources',
        source: 'anubis-botPolicies.yaml.erb',
        variables: {
          import_bots: %w(
            (data)/bots/_deny-pathological.yaml
            (data)/bots/aggressive-brazilian-scrapers.yaml
            (data)/meta/ai-block-aggressive.yaml
            (data)/crawlers/_allow-good.yaml
            (data)/clients/x-firefox-ai.yaml
            (data)/common/keep-internet-working.yaml
          ),
          custom_bots: nil,
          extra_config: nil,
        }
      )
    end

    it do
      expect(chef_run.template('/etc/anubis/botPolicies-default.yaml')).to \
        notify('service[anubis@default.service]').to(:restart)
    end

    it { is_expected.to enable_service 'anubis@default.service' }
    it { is_expected.to start_service 'anubis@default.service' }
  end
end
