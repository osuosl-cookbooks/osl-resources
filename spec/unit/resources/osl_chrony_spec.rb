require_relative '../../spec_helper'

describe 'osl_chrony' do
  cached(:subject) { chef_run }
  step_into :osl_chrony

  recipe do
    osl_chrony 'default'
  end

  context 'almalinux' do
    cached(:subject) { chef_run }

    platform 'almalinux', '9'
    automatic_attributes['ipaddress'] = '140.211.166.10'

    it { is_expected.to disable_service('ntp').with(service_name: 'ntpd') }
    it { is_expected.to stop_service('ntp').with(service_name: 'ntpd') }
    it { is_expected.to disable_service('systemd-timesyncd') }
    it { is_expected.to stop_service('systemd-timesyncd') }
    it { is_expected.to install_package 'chrony' }
    it { is_expected.to enable_service('chrony').with(service_name: 'chronyd') }
    it { is_expected.to start_service('chrony').with(service_name: 'chronyd') }
    it do
      is_expected.to create_template('/etc/chrony.conf').with(
        cookbook: 'osl-resources',
        source: 'chrony.conf.erb'
      )
    end
    it { expect(chef_run.template('/etc/chrony.conf')).to notify('service[chrony]').to(:restart) }
    [
      /^pool time\.osuosl\.org iburst maxsources 3$/,
      /^pool 2\.pool\.ntp\.org iburst maxsources 2$/,
      %r{^driftfile /var/lib/chrony/drift$},
      /^makestep 1\.0 3$/,
      /^rtcsync$/,
      %r{^logdir /var/log/chrony$},
      /^port 0$/,
      /^cmdport 0$/,
    ].each do |line|
      it { is_expected.to render_file('/etc/chrony.conf').with_content(line) }
    end
    [
      /time-ext\.osuosl\.org/,
      /centos\.pool\.ntp\.org/,
      /^server /,
      /^peer /,
      /^allow/,
      /^keyfile/,
      /^ntsservercert/,
    ].each do |line|
      it { is_expected.to_not render_file('/etc/chrony.conf').with_content(line) }
    end
    it { is_expected.to_not create_template('/etc/chrony.keys') }
  end

  context 'debian' do
    cached(:subject) { chef_run }

    platform 'debian', '12'
    automatic_attributes['ipaddress'] = '140.211.166.10'

    it { is_expected.to disable_service('ntp').with(service_name: 'ntp') }
    it { is_expected.to enable_service('chrony').with(service_name: 'chrony') }
    it do
      is_expected.to create_template('/etc/chrony/chrony.conf').with(
        cookbook: 'osl-resources',
        source: 'chrony.conf.erb'
      )
    end
    [
      /^pool time\.osuosl\.org iburst maxsources 3$/,
      %r{^driftfile /var/lib/chrony/chrony.drift$},
      /^port 0$/,
    ].each do |line|
      it { is_expected.to render_file('/etc/chrony/chrony.conf').with_content(line) }
    end
  end
end
