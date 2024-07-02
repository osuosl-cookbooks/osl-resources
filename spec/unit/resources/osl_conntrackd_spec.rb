require_relative '../../spec_helper'

describe 'osl_conntrackd' do
  platform 'almalinux', '8'
  cached(:subject) { chef_run }
  step_into :osl_conntrackd

  recipe do
    osl_conntrackd '192.168.0.2' do
      interface 'eth0'
      ipv4_destination_address '192.168.0.3'
      address_ignore %w(127.0.0.1 192.168.0.1 192.168.0.2 192.168.0.3)
    end
  end

  it do
    is_expected.to create_osl_conntrackd('192.168.0.2').with(
      interface: 'eth0',
      ipv4_destination_address: '192.168.0.3',
      address_ignore: %w(127.0.0.1 192.168.0.1 192.168.0.2 192.168.0.3)
    )
  end

  it { is_expected.to install_package 'conntrack-tools' }

  it do
    is_expected.to create_template('/etc/conntrackd/conntrackd.conf').with(
      source: 'conntrackd.conf.erb',
      cookbook: 'osl-resources',
      owner: 'root',
      group: 'root',
      mode: '0644',
      variables: {
        interface: 'eth0',
        ipv4_address: '192.168.0.2',
        ipv4_destination_address: '192.168.0.3',
        address_ignore: %w(127.0.0.1 192.168.0.1 192.168.0.2 192.168.0.3),
      }
    )
  end

  it do
    is_expected.to create_remote_file('/etc/conntrackd/primary-backup.sh').with(
      source: 'file:///usr/share/doc/conntrack-tools/doc/sync/primary-backup.sh',
      mode: '0755'
    )
  end

  it { is_expected.to enable_service('conntrackd') }
  it { is_expected.to start_service('conntrackd') }
end
