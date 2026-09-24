require 'spec_helper'

describe 'osl_anubis' do
  context 'almalinux' do
    recipe do
      osl_anubis 'default'
    end

    platform 'almalinux'
    automatic_attributes['memory']['total'] = '8388608kB'
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
          extra_env: { 'GOMEMLIMIT' => '4096MiB', 'SLOG_LEVEL' => 'WARN' },
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

    # Half of the 8 GiB the node reports, as a soft limit for the Go runtime
    it { is_expected.to render_file('/etc/anubis/default.env').with_content(/^GOMEMLIMIT=4096MiB$/) }

    # Anubis logs a line per challenge decision at its own INFO default
    it { is_expected.to render_file('/etc/anubis/default.env').with_content(/^SLOG_LEVEL=WARN$/) }

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
          store: { 'backend' => 'valkey', 'parameters' => { 'url' => 'redis://127.0.0.1:6390/0' } },
        }
      )
    end

    it do
      expect(chef_run.template('/etc/anubis/botPolicies-default.yaml')).to \
        notify('service[anubis@default.service]').to(:restart)
    end

    # EL 9.7+ gets valkey@anubis rather than bbolt
    it do
      is_expected.to render_file('/etc/anubis/botPolicies-default.yaml').with_content(
        "store:\n  backend: valkey\n  parameters:\n    url: redis://127.0.0.1:6390/0\n"
      )
    end

    it do
      is_expected.to create_osl_valkey('anubis').with(
        instance: true,
        port: 6390,
        bind: '127.0.0.1',
        firewall: false,
        maxmemory: '2gb',
        maxmemory_policy: 'allkeys-lru',
        save: '',
        config: {},
        config_version: 1
      )
    end

    it { is_expected.to_not create_osl_systemd_unit_drop_in('restart') }

    it do
      is_expected.to create_osl_systemd_unit_drop_in('after-valkey').with(
        unit_name: 'anubis@default.service',
        content: { 'Unit' => { 'After' => 'valkey@anubis.service', 'Wants' => 'valkey@anubis.service' } }
      )
    end

    # The database a bbolt-backed instance left behind
    it { is_expected.to delete_file '/var/lib/anubis/default/anubis.bdb' }

    it do
      is_expected.to accept_osl_firewall_port('anubis-metrics-default').with(
        ports: %w(9090),
        osl_only: true
      )
    end

    # Registered so the prometheus server can discover this instance
    it { expect(chef_run.node['osl-resources']['anubis']['default']).to eq('9090') }

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
    automatic_attributes['memory']['total'] = '8388608kB'
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
            'GOMEMLIMIT' => '4096MiB',
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

    it do
      expect(chef_run.node['osl-resources']['anubis']['default']).to eq('9091')
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

    # The store from extra_config replaces the default rather than joining it
    it { expect(subject.template('/etc/anubis/botPolicies-default.yaml').variables[:store]).to be_nil }
    it { is_expected.to_not render_file('/etc/anubis/botPolicies-default.yaml').with_content(%r{anubis/default/anubis\.bdb}) }

    # That store is bbolt, so there is no valkey to manage and nothing stale
    it { is_expected.to_not create_osl_valkey('anubis') }
    it { is_expected.to_not delete_file '/var/lib/anubis/default/anubis.bdb' }
  end

  context 'almalinux with memory_limit and store overrides' do
    recipe do
      osl_anubis 'default' do
        memory_limit '3GiB'
        store('backend' => 'memory')
      end
    end

    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    it { is_expected.to render_file('/etc/anubis/default.env').with_content(/^GOMEMLIMIT=3GiB$/) }
    it { is_expected.to render_file('/etc/anubis/botPolicies-default.yaml').with_content(/^store:\n  backend: memory$/) }
    it { is_expected.to_not render_file('/etc/anubis/botPolicies-default.yaml').with_content(/bbolt/) }
    it { is_expected.to_not create_osl_valkey('anubis') }
    it { is_expected.to delete_file '/var/lib/anubis/default/anubis.bdb' }
  end

  # valkey ships in AppStream from EL 9.7; fauxhai's EL9 is 9.1, so pin a real one
  context 'almalinux 9.8' do
    recipe do
      osl_anubis 'default'
    end

    platform 'almalinux', '9'
    automatic_attributes['platform_version'] = '9.8'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    it { is_expected.to create_osl_valkey('anubis') }
    it { is_expected.to render_file('/etc/anubis/botPolicies-default.yaml').with_content(/^  backend: valkey$/) }
  end

  # Anywhere without the valkey package the instance stays on bbolt
  {
    'almalinux 8' => %w(almalinux 8),
    'almalinux 9 before 9.7' => %w(almalinux 9),
  }.each do |desc, (plat, ver)|
    context desc do
      recipe do
        osl_anubis 'default'
      end

      platform plat, ver
      cached(:subject) { chef_run }
      step_into :osl_anubis

      it { is_expected.to_not create_osl_valkey('anubis') }
      it { is_expected.to_not create_osl_systemd_unit_drop_in('after-valkey') }
      it { is_expected.to_not delete_file '/var/lib/anubis/default/anubis.bdb' }

      it do
        is_expected.to render_file('/etc/anubis/botPolicies-default.yaml').with_content(
          %r{^store:\n  backend: bbolt\n  parameters:\n    path: "?/var/lib/anubis/default/anubis\.bdb"?$}
        )
      end
    end
  end

  context 'almalinux with valkey turned off' do
    recipe do
      osl_anubis 'default' do
        valkey false
      end
    end

    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    it { is_expected.to_not create_osl_valkey('anubis') }
    it { is_expected.to render_file('/etc/anubis/botPolicies-default.yaml').with_content(/^  backend: bbolt$/) }
  end

  # A caller that must have valkey, like the LBs, forces it on
  context 'almalinux 8 with valkey forced on' do
    recipe do
      osl_anubis 'default' do
        valkey true
      end
    end

    platform 'almalinux', '8'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    it { is_expected.to create_osl_valkey('anubis') }
    it { is_expected.to render_file('/etc/anubis/botPolicies-default.yaml').with_content(/^  backend: valkey$/) }
  end

  context 'almalinux with valkey settings' do
    recipe do
      osl_anubis 'default' do
        valkey_maxmemory '512mb'
        valkey_config_version 2
        valkey_port 6391
      end
    end

    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    it do
      is_expected.to create_osl_valkey('anubis').with(
        maxmemory: '512mb',
        port: 6391,
        config_version: 2
      )
    end
    it { is_expected.to render_file('/etc/anubis/botPolicies-default.yaml').with_content(%r{url: redis://127\.0\.0\.1:6391/0$}) }
  end

  context 'almalinux with a log_level override' do
    recipe do
      osl_anubis 'default' do
        log_level 'INFO'
      end
    end

    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    it { is_expected.to render_file('/etc/anubis/default.env').with_content(/^SLOG_LEVEL=INFO$/) }
  end

  context 'almalinux with GOMEMLIMIT in extra_env' do
    recipe do
      osl_anubis 'default' do
        memory_limit '3GiB'
        extra_env('GOMEMLIMIT' => '2GiB')
      end
    end

    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    # extra_env is the escape hatch, so it wins over the property
    it { is_expected.to render_file('/etc/anubis/default.env').with_content(/^GOMEMLIMIT=2GiB$/) }
    it { is_expected.to_not render_file('/etc/anubis/default.env').with_content(/3GiB/) }
  end
  context 'remove' do
    recipe do
      osl_anubis 'default' do
        action :remove
      end
    end

    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    it { is_expected.to stop_service 'anubis@default.service' }
    it { is_expected.to disable_service 'anubis@default.service' }

    %w(
      /etc/anubis/default.env
      /etc/anubis/botPolicies-default.yaml
      /etc/anubis/default.key
    ).each do |f|
      it { is_expected.to delete_file f }
    end

    # The unit is templated, so other instances may still need the package
    it { is_expected.to_not remove_package 'anubis' }
  end

  # valkey@anubis is shared, so it goes only with the last instance on the host
  {
    'the last instance' => [%w(/etc/anubis/default.env), true],
    'one of several instances' => [%w(/etc/anubis/default.env /etc/anubis/keeper.env), false],
  }.each do |desc, (env_files, deleted)|
    context "remove #{desc}" do
      recipe do
        osl_anubis 'default' do
          action :remove
        end
      end

      platform 'almalinux'
      cached(:subject) { chef_run }
      step_into :osl_anubis

      before do
        allow(Dir).to receive(:glob).and_call_original
        allow(Dir).to receive(:glob).with('/etc/anubis/*.env').and_return(env_files)
      end

      if deleted
        it { is_expected.to delete_osl_valkey('anubis').with(instance: true) }
      else
        it { is_expected.to_not delete_osl_valkey('anubis') }
      end
    end
  end

  # No valkey where the platform has none, whatever else is left
  context 'remove the last instance on almalinux 8' do
    recipe do
      osl_anubis 'default' do
        action :remove
      end
    end

    platform 'almalinux', '8'
    cached(:subject) { chef_run }
    step_into :osl_anubis

    before do
      allow(Dir).to receive(:glob).and_call_original
      allow(Dir).to receive(:glob).with('/etc/anubis/*.env').and_return(%w(/etc/anubis/default.env))
    end

    it { is_expected.to_not delete_osl_valkey('anubis') }
  end
end
