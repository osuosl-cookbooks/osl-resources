require_relative '../../spec_helper'

describe 'osl_hpnssh' do
  platform 'almalinux'
  cached(:subject) { chef_run }
  step_into :osl_hpnssh

  recipe do
    osl_hpnssh 'default'
  end

  it { is_expected.to enable_osl_dnf_copr('rapier1/hpnssh') }
  it { is_expected.to install_package(%w(hpnssh hpnssh-clients hpnssh-server)) }

  it do
    is_expected.to create_template('/etc/hpnssh/sshd_config').with(
      cookbook: 'osl-resources',
      source: 'hpnsshd_config.erb',
      owner: 'root',
      group: 'root',
      mode: '0600',
      variables: {
        port: 2222,
        extra_options: [],
      }
    )
  end

  it do
    expect(chef_run.template('/etc/hpnssh/sshd_config')).to notify('service[hpnsshd]').to(:restart)
  end

  it { is_expected.to enable_service('hpnsshd') }
  it { is_expected.to start_service('hpnsshd') }
end

describe 'osl_hpnssh with custom port and extra_options' do
  platform 'almalinux'
  cached(:subject) { chef_run }
  step_into :osl_hpnssh

  recipe do
    osl_hpnssh 'custom' do
      port 2200
      extra_options ['UseDNS no', 'PermitRootLogin prohibit-password']
    end
  end

  it do
    is_expected.to create_template('/etc/hpnssh/sshd_config').with(
      variables: {
        port: 2200,
        extra_options: ['UseDNS no', 'PermitRootLogin prohibit-password'],
      }
    )
  end
end
