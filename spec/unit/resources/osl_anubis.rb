require 'spec_helper'

describe 'osl_anubis' do
  context 'almalinux' do
    recipe do
      osl_anubis 'default'
    end

    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    it { is_expected.to include_recipe 'yum-osuosl' }
    it { is_expected.to install_package 'anubis' }

    # systemd manages this via RuntimeDirectory=anubis/%i
    it { is_expected.to_not create_directory '/run/anubis' }

    it do
      is_expected.to create_template('/etc/anubis/default.env').with(
        cookbook: 'osl-resources',
        source: 'anubis.env.erb',
        owner: 'root',
        group: 'root',
        mode: '0600',
        variables: {
          bind_network: 'tcp',
          bind: '127.0.0.1:8932',
          cookie_domain: nil,
          cookie_expiration_time: '168h',
          cookie_partitioned: 'true',
          ed25519_private_key_hex: subject.file('/etc/anubis/default.key').content,
          extra_env: nil,
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
      is_expected.to create_file('/etc/anubis/default.key').with(
        owner: 'root',
        group: 'root',
        mode: '0600',
        sensitive: true
      )
    end

    it do
      expect(subject.file('/etc/anubis/default.key')).to \
        notify('service[anubis@default.service]').to(:restart)
    end

    it { expect(subject.file('/etc/anubis/default.key').content).to match(/\A[0-9a-f]{64}\z/) }

    # The env file carries the key, since DynamicUser cannot read the key file
    it { is_expected.to create_template('/etc/anubis/default.env').with(sensitive: true) }

    it do
      expect(subject.template('/etc/anubis/default.env').variables[:ed25519_private_key_hex]).to \
        eq subject.file('/etc/anubis/default.key').content
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
            (data)/crawlers/xai.yaml
            (data)/common/keep-internet-working.yaml
          ),
          custom_bots: nil,
          default_challenge: { 'algorithm' => 'fast', 'difficulty' => 4 },
          extra_config: nil,
        }
      )
    end

    it do
      expect(chef_run.template('/etc/anubis/botPolicies-default.yaml')).to \
        notify('service[anubis@default.service]').to(:restart)
    end

    it do
      is_expected.to accept_osl_firewall_port('anubis-metrics-default').with(
        ports: %w(9090),
        osl_only: true
      )
    end

    it { is_expected.to enable_service 'anubis@default.service' }
    it { is_expected.to start_service 'anubis@default.service' }
  end

  context 'almalinux without redirect_domains' do
    recipe do
      osl_anubis 'default'
    end

    platform 'almalinux'
    step_into :osl_anubis

    it do
      allow(Chef::Log).to receive(:warn)
      expect(Chef::Log).to receive(:warn).with(/redirect_domains is not set/)
      chef_run
    end
  end

  context 'almalinux with redirect_domains' do
    recipe do
      osl_anubis 'default' do
        redirect_domains 'example.org'
      end
    end

    platform 'almalinux'
    step_into :osl_anubis

    it do
      allow(Chef::Log).to receive(:warn)
      expect(Chef::Log).to_not receive(:warn).with(/redirect_domains is not set/)
      chef_run
    end
  end

  context 'almalinux with extra env and signing key' do
    recipe do
      osl_anubis 'default' do
        ed25519_private_key_hex '4f2b8c1d9e3a7056b4c8d2f1a903e5b7c6d4082f1e9a3b5c7d08f2a4e6b1c3d5'
        metrics_bind '127.0.0.1:9091'
        redirect_domains 'example.org'
        extra_env(
          'SLOG_LEVEL' => 'DEBUG',
          'CUSTOM_REAL_IP_HEADER' => 'X-Real-IP'
        )
      end
    end

    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    # An explicit key wins over anything persisted, keeping an LB pair in sync
    it do
      is_expected.to create_file('/etc/anubis/default.key').with(
        content: '4f2b8c1d9e3a7056b4c8d2f1a903e5b7c6d4082f1e9a3b5c7d08f2a4e6b1c3d5',
        mode: '0600',
        sensitive: true
      )
    end

    it do
      expect(subject.template('/etc/anubis/default.env').variables[:ed25519_private_key_hex]).to \
        eq '4f2b8c1d9e3a7056b4c8d2f1a903e5b7c6d4082f1e9a3b5c7d08f2a4e6b1c3d5'
    end

    it do
      is_expected.to create_template('/etc/anubis/default.env').with(
        variables: {
          bind_network: 'tcp',
          bind: '127.0.0.1:8932',
          cookie_domain: nil,
          cookie_expiration_time: '168h',
          cookie_partitioned: 'true',
          ed25519_private_key_hex: '4f2b8c1d9e3a7056b4c8d2f1a903e5b7c6d4082f1e9a3b5c7d08f2a4e6b1c3d5',
          extra_env: {
            'SLOG_LEVEL' => 'DEBUG',
            'CUSTOM_REAL_IP_HEADER' => 'X-Real-IP',
          },
          metrics_bind: '127.0.0.1:9091',
          policy_fname: '/etc/anubis/botPolicies-default.yaml',
          redirect_domains: 'example.org',
          serve_robots_txt: 'false',
          target: nil,
          webmaster_email: nil,
        }
      )
    end

    it do
      is_expected.to accept_osl_firewall_port('anubis-metrics-default').with(ports: %w(9091))
    end
  end

  # Values from node attributes arrive as Mashes; YAML.dump tags those as
  # !ruby/hash, which anubis cannot parse.
  context 'almalinux with custom_bots and extra_config from node attributes' do
    recipe do
      node.default['test']['custom_bots'] = [
        { 'name' => 'attr-bot', 'user_agent_regex' => 'AttrBot', 'action' => 'DENY' },
      ]
      node.default['test']['extra_config'] = {
        'store' => { 'backend' => 'bbolt', 'parameters' => { 'path' => '/var/lib/anubis/x.bdb' } },
      }

      osl_anubis 'default' do
        custom_bots node['test']['custom_bots']
        extra_config node['test']['extra_config']
      end
    end

    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    it do
      is_expected.to_not render_file('/etc/anubis/botPolicies-default.yaml').with_content(/!ruby/)
    end

    [
      /^  - name: attr-bot$/,
      /^    user_agent_regex: AttrBot$/,
      /^    action: DENY$/,
      /^store:$/,
      /^  backend: bbolt$/,
      %r{^    path: "?/var/lib/anubis/x\.bdb"?$},
    ].each do |line|
      it { is_expected.to render_file('/etc/anubis/botPolicies-default.yaml').with_content(line) }
    end
  end
end
