require 'spec_helper'

describe 'osl_route' do
  recipe do
    osl_route 'eth1' do
      routes [
        {
          address: '10.50.0.0',
          netmask: '255.255.254.0',
          gateway: '10.30.0.1',
        },
      ]
    end

    osl_route 'eth2' do
      routes [
        {
          address: '10.60.0.0',
          netmask: '255.255.254.0',
        },
        {
          address: '10.70.0.0',
          netmask: '255.255.254.0',
          gateway: '10.40.0.1',
        },
      ]
    end

    osl_route 'eth3' do
      routes [
        {
          address: '10.80.0.0',
          netmask: '255.255.254.0',
          gateway: '10.40.0.1',
        },
      ]
      action :remove
    end
  end

  context 'almalinux 8' do
    platform 'almalinux', '8'
    cached(:subject) { chef_run }
    step_into :osl_route

    [
      /^ADDRESS0=10.50.0.0$/,
      /^NETMASK0=255.255.254.0$/,
      /^GATEWAY0=10.30.0.1$/,
    ].each do |line|
      it { is_expected.to render_file('/etc/sysconfig/network-scripts/route-eth1').with_content(line) }
    end

    [
      /^ADDRESS0=10.60.0.0$/,
      /^NETMASK0=255.255.254.0$/,
      /^ADDRESS1=10.70.0.0$/,
      /^NETMASK1=255.255.254.0$/,
      /^GATEWAY1=10.40.0.1$/,
    ].each do |line|
      it { is_expected.to render_file('/etc/sysconfig/network-scripts/route-eth2').with_content(line) }
    end
    it { is_expected.to_not render_file('/etc/sysconfig/network-scripts/route-eth2').with_content(/^GATEWAY0/) }
  end

  context 'almalinux 9' do
    platform 'almalinux', '9'
    cached(:subject) { chef_run }
    step_into :osl_route

    it { is_expected.to install_package 'nmstate' }
    it { is_expected.to create_directory '/etc/nmstate' }

    it do
      is_expected.to create_template('/etc/nmstate/route-eth1.yml').with(
        source: 'nmstate-route.yml.erb',
        cookbook: 'osl-resources',
        mode: '0640',
        variables: {
          routes: [
            {
              destination: '10.50.0.0/23',
              next_hop_address: '10.30.0.1',
              next_hop_interface: 'eth1',
            },
          ],
          state: nil,
        }
      )
    end

    it do
      is_expected.to create_template('/etc/nmstate/route-eth2.yml').with(
        source: 'nmstate-route.yml.erb',
        cookbook: 'osl-resources',
        mode: '0640',
        variables: {
          routes: [
            {
              destination: '10.60.0.0/23',
              next_hop_address: nil,
              next_hop_interface: 'eth2',
            },
            {
              destination: '10.70.0.0/23',
              next_hop_address: '10.40.0.1',
              next_hop_interface: 'eth2',
            },
          ],
          state: nil,
        }
      )
    end

    it do
      is_expected.to create_template('/etc/nmstate/route-eth3.yml').with(
        source: 'nmstate-route.yml.erb',
        cookbook: 'osl-resources',
        mode: '0640',
        variables: {
          routes: [
            {
              destination: '10.80.0.0/23',
              next_hop_address: '10.40.0.1',
              next_hop_interface: 'eth3',
            },
          ],
          state: 'absent',
        }
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/route-eth1.yml').with_content(
        <<~EOF
          ---
          # nmstate config file written by Chef
          routes:
            config:
              - destination: 10.50.0.0/23
                next-hop-interface: eth1
                next-hop-address: 10.30.0.1
        EOF
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/route-eth2.yml').with_content(
        <<~EOF
          ---
          # nmstate config file written by Chef
          routes:
            config:
              - destination: 10.60.0.0/23
                next-hop-interface: eth2
                next-hop-address:#{' '}
              - destination: 10.70.0.0/23
                next-hop-interface: eth2
                next-hop-address: 10.40.0.1
        EOF
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/route-eth3.yml').with_content(
        <<~EOF
          ---
          # nmstate config file written by Chef
          routes:
            config:
              - destination: 10.80.0.0/23
                next-hop-interface: eth3
                next-hop-address: 10.40.0.1
                state: absent
        EOF
      )
    end
    %w(
      eth1
      eth2
      eth3
    ).each do |i|
      it do
        expect(chef_run.template("/etc/nmstate/route-#{i}.yml")).to \
          notify("execute[nmstatectl apply -q /etc/nmstate/route-#{i}.yml]").to(:run).immediately
      end
    end
  end
end
