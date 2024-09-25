require_relative '../../spec_helper'

describe 'osl_nfdump' do
  platform 'almalinux', '8'
  cached(:subject) { chef_run }
  step_into :osl_nfdump

  recipe do
    osl_nfdump 'default'
  end

  it { is_expected.to include_recipe 'osl-repos::epel' }
  it { is_expected.to install_package 'nfdump' }
  it { is_expected.to create_directory('/var/cache/nfdump/default').with(recursive: true) }

  it do
    is_expected.to create_systemd_unit('nfdump-default.service').with(
      content: <<~EOU
        [Unit]
        Description=nfcapd capture daemon, default instance
        After=network.target auditd.service

        [Service]
        Type=forking
        ExecStart=/usr/bin/nfcapd -D -P /run/nfcapd.default.pid -l /var/cache/nfdump/default -p 2055#{' '}
        PIDFile=/run/nfcapd.default.pid
        KillMode=process
        Restart=no

        [Install]
        WantedBy=multi-user.target
      EOU
    )
  end

  it { is_expected.to enable_service 'nfdump-default.service' }
  it { is_expected.to start_service 'nfdump-default.service' }

  it do
    expect(chef_run.service('nfdump-default.service')).to \
      subscribe_to('systemd_unit[nfdump-default.service]').on(:restart)
  end

  context 'sflow' do
    platform 'almalinux', '8'
    cached(:subject) { chef_run }
    step_into :osl_nfdump

    recipe do
      osl_nfdump 'default' do
        type :sflow
      end
    end

    it do
      is_expected.to create_systemd_unit('nfdump-default.service').with(
        content: <<~EOU
          [Unit]
          Description=sfcapd capture daemon, default instance
          After=network.target auditd.service

          [Service]
          Type=forking
          ExecStart=/usr/bin/sfcapd -D -P /run/sfcapd.default.pid -l /var/cache/nfdump/default -p 2055#{' '}
          PIDFile=/run/sfcapd.default.pid
          KillMode=process
          Restart=no

          [Install]
          WantedBy=multi-user.target
        EOU
      )
    end
  end
end
