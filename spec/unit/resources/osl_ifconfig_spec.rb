require_relative '../../spec_helper'

describe 'osl_ifconfig' do
  before do
    stub_command('ip link show dev eth4 | grep \'UP\'').and_return(false)
    stub_command('ip link show dev eth4 | grep \'DOWN\'').and_return(false)
  end

  recipe do
    osl_ifconfig 'eth1' do
      bootproto 'none'
      nm_controlled 'no'
      device 'eth1'
      type 'dummy'
    end

    osl_ifconfig 'eth2' do
      device 'eth2'
      ipv4addr '172.16.50.10'
      mask '255.255.255.0'
      network '172.16.50.0'
      bootproto 'static'
      onboot 'yes'
      ipv6init 'yes'
      ipv6addr '2001:db8::2/32'
      ipv6_defaultgw '2001:db8::1/32'
      type 'dummy'
    end

    osl_ifconfig 'eth3' do
      device 'eth3'
      ipv4addr %w(
        10.1.30.20
        10.1.30.21
      )
      onboot 'yes'
      ipv6init 'yes'
      ipv6addr '2001:db8::3/32'
      ipv6addrsec %w(
        2001:db8::4/32
        2001:db8::5/32
      )
      ipv6_defaultgw '2001:db8::1/32'
      nm_controlled 'yes'
      type 'dummy'
    end

    osl_ifconfig 'eth4' do
      device 'eth4'
      type 'dummy'
      action [:enable, :disable]
    end

    osl_ifconfig 'eth5' do
      device 'eth5'
      nm_controlled 'no'
      type 'dummy'
      ipv4addr '10.1.30.20'
      action [:add, :delete]
    end

    osl_ifconfig 'eth6' do
      device 'eth6'
      onboot 'yes'
      bootproto 'static'
      ipv6init 'yes'
      ipv6_autoconf 'no'
      type 'dummy'
    end

    osl_ifconfig 'bond0' do
      ipv4addr '172.16.20.10'
      mask '255.255.255.0'
      network '172.16.20.0'
      device 'bond0'
      bootproto 'static'
      bonding_opts 'mode=4 miimon=100 lacp_rate=0'
      onboot 'yes'
    end

    osl_ifconfig 'eth1.172' do
      onboot 'yes'
      bootproto 'none'
      nm_controlled 'no'
      userctl 'no'
      vlan 'yes'
      bridge 'br172'
    end

    osl_ifconfig 'br172' do
      type 'linux-bridge'
      bridge_ports %w(eth1.172)
      onboot 'yes'
      bootproto 'none'
      nm_controlled 'no'
      delay '0'
    end

    osl_ifconfig 'br42' do
      type 'linux-bridge'
      bridge_ports %w(eno1.42)
      bridge_options(
        stp: { enabled: false, 'forward-delay': 2 }
      )
      onboot 'yes'
      bootproto 'static'
      ipv4addr '192.168.42.1'
      mask '255.255.255.0'
    end
  end

  context 'almalinux 8' do
    platform 'almalinux', '8'
    cached(:subject) { chef_run }
    step_into :osl_ifconfig

    it do
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-eth1')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bcast: nil,
            bonding_opts: nil,
            bootproto: 'none',
            bridge: nil,
            defroute: nil,
            delay: nil,
            device: 'eth1',
            ethtool_opts: nil,
            gateway: nil,
            hwaddr: nil,
            ipv4addr: [],
            ipv6addr: [],
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: [],
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            type: 'dummy',
            userctl: nil,
            vlan: nil,
          }
        )
    end
    it do
      expect(chef_run.template('/etc/sysconfig/network-scripts/ifcfg-eth1')).to \
        notify('execute[ifup eth1]').immediately
    end
    it do
      expect(chef_run).to nothing_execute('ifup eth1')
    end

    it do
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-eth2')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bcast: nil,
            bonding_opts: nil,
            bootproto: 'static',
            bridge: nil,
            defroute: nil,
            delay: nil,
            device: 'eth2',
            ethtool_opts: nil,
            gateway: nil,
            hwaddr: nil,
            ipv4addr: %w(172.16.50.10),
            ipv6addrsec: nil,
            ipv6addr: %w(2001:db8::2/32),
            ipv6_autoconf: nil,
            ipv6_defaultgw: '2001:db8::1/32',
            ipv6init: 'yes',
            mask: %w(255.255.255.0),
            master: nil,
            metric: nil,
            mtu: nil,
            network: '172.16.50.0',
            nm_controlled: 'yes',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            type: 'dummy',
            userctl: nil,
            vlan: nil,
          }
        )
    end
    it do
      expect(chef_run.template('/etc/sysconfig/network-scripts/ifcfg-eth2')).to \
        notify('execute[ifup eth2]').immediately
    end
    it do
      expect(chef_run).to nothing_execute('ifup eth2')
    end

    it do
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-eth3')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bcast: nil,
            bonding_opts: nil,
            bootproto: nil,
            bridge: nil,
            defroute: nil,
            delay: nil,
            device: 'eth3',
            ethtool_opts: nil,
            gateway: nil,
            hwaddr: nil,
            ipv4addr: %w(
              10.1.30.20
              10.1.30.21
            ),
            ipv6addr: %w(2001:db8::3/32),
            ipv6addrsec: %w(
              2001:db8::4/32
              2001:db8::5/32
            ),
            ipv6_autoconf: nil,
            ipv6_defaultgw: '2001:db8::1/32',
            ipv6init: 'yes',
            mask: [],
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'yes',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            type: 'dummy',
            userctl: nil,
            vlan: nil,
          }
        )
    end
    it do
      expect(chef_run.template('/etc/sysconfig/network-scripts/ifcfg-eth3')).to \
        notify('execute[ifup eth3]').immediately
    end
    it do
      expect(chef_run).to nothing_execute('ifup eth3')
    end

    it do
      expect(chef_run).to run_execute('ifup eth4')
    end
    it do
      expect(chef_run).to run_execute('ifdown eth4')
    end

    it do
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-eth5')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          mode: '0640'
        )
    end
    it do
      expect(chef_run.template('/etc/sysconfig/network-scripts/ifcfg-eth5')).to \
        notify('execute[ifup eth5]').immediately
    end
    it do
      expect(chef_run).to nothing_execute('ifup eth5')
    end

    it do
      is_expected.to create_file('/etc/sysconfig/network-scripts/ifcfg-eth5').with(
        content: <<~EOF
          # ifcfg config file written by Chef
          DEVICE=eth5
          ONBOOT=no
          TYPE=none
        EOF
      )
    end
    it do
      expect(chef_run.file('/etc/sysconfig/network-scripts/ifcfg-eth5')).to \
        notify('execute[ifdown eth5]').immediately
    end
    it do
      expect(chef_run).to nothing_execute('ifdown eth5')
    end

    it do
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-bond0')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bcast: nil,
            bonding_opts: 'mode=4 miimon=100 lacp_rate=0',
            bootproto: 'static',
            bridge: nil,
            defroute: nil,
            delay: nil,
            device: 'bond0',
            ethtool_opts: nil,
            gateway: nil,
            hwaddr: nil,
            ipv4addr: %w(172.16.20.10),
            ipv6addr: [],
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: %w(255.255.255.0),
            master: nil,
            metric: nil,
            mtu: nil,
            network: '172.16.20.0',
            nm_controlled: 'yes',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            type: nil,
            userctl: nil,
            vlan: nil,
          }
        )
    end
    it do
      expect(chef_run.template('/etc/sysconfig/network-scripts/ifcfg-bond0')).to \
        notify('execute[ifup bond0]').immediately
    end
    it do
      expect(chef_run).to nothing_execute('ifup bond0')
    end

    it do
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-br172')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bcast: nil,
            bonding_opts: nil,
            bootproto: 'none',
            bridge: nil,
            defroute: nil,
            delay: '0',
            device: 'br172',
            ethtool_opts: nil,
            gateway: nil,
            hwaddr: nil,
            ipv4addr: [],
            ipv6addr: [],
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: [],
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            type: 'Bridge',
            userctl: nil,
            vlan: nil,
          }
        )
    end
    it do
      expect(chef_run.template('/etc/sysconfig/network-scripts/ifcfg-br172')).to \
        notify('execute[ifup br172]').immediately
    end
    it do
      expect(chef_run).to nothing_execute('ifup br172')
    end

    it do
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-eth1.172')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bcast: nil,
            bonding_opts: nil,
            bootproto: 'none',
            bridge: 'br172',
            defroute: nil,
            delay: nil,
            device: 'eth1.172',
            ethtool_opts: nil,
            gateway: nil,
            hwaddr: nil,
            ipv4addr: [],
            ipv6addr: [],
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: [],
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            type: nil,
            userctl: 'no',
            vlan: 'yes',
          }
        )
    end
    it do
      expect(chef_run.template('/etc/sysconfig/network-scripts/ifcfg-eth1.172')).to \
        notify('execute[ifup eth1.172]').immediately
    end
    it do
      expect(chef_run).to nothing_execute('ifup eth1.172')
    end

    it do
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-br42')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bcast: nil,
            bonding_opts: nil,
            bootproto: 'static',
            bridge: nil,
            defroute: nil,
            delay: nil,
            device: 'br42',
            ethtool_opts: nil,
            gateway: nil,
            hwaddr: nil,
            ipv4addr: %w(192.168.42.1),
            ipv6addr: [],
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: %w(255.255.255.0),
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'yes',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            type: 'Bridge',
            userctl: nil,
            vlan: nil,
          }
        )
    end
    it do
      expect(chef_run.template('/etc/sysconfig/network-scripts/ifcfg-br42')).to \
        notify('execute[ifup br42]').immediately
    end
    it do
      expect(chef_run).to nothing_execute('ifup br42')
    end
  end

  context 'almalinux 9' do
    platform 'almalinux', '9'
    cached(:subject) { chef_run }
    step_into :osl_ifconfig

    it { is_expected.to install_package 'nmstate' }
    it { is_expected.to_not install_package 'network-scripts' }
    it { is_expected.to_not install_package 'bridge-utils' }
    it { is_expected.to create_directory '/etc/nmstate' }

    it do
      is_expected.to create_template('/etc/nmstate/eth1.yml')
        .with(
          source: 'nmstate.yml.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bonding_opts: nil,
            bond_ports: [],
            bridge: nil,
            bridge_options: nil,
            bridge_ports: [],
            device: 'eth1',
            enabled: true,
            ethtool_opts: nil,
            gateway: nil,
            interface: 'eth1',
            ipv4addresses: [],
            ipv6addrsec: nil,
            ipv6addr: [],
            ipv6init: nil,
            ipv6_autoconf: false,
            ipv6_defaultgw: nil,
            mac_address: nil,
            mask: [],
            mtu: nil,
            state: 'up',
            type: 'dummy',
            vlan: nil,
            vlan_device: 'eth1',
            vlan_id: nil,
          }
        )
    end

    it do
      is_expected.to create_template('/etc/nmstate/eth2.yml')
        .with(
          source: 'nmstate.yml.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bonding_opts: nil,
            bond_ports: [],
            bridge: nil,
            bridge_options: nil,
            bridge_ports: [],
            device: 'eth2',
            enabled: true,
            ethtool_opts: nil,
            gateway: nil,
            interface: 'eth2',
            ipv4addresses: [{ ipaddress: '172.16.50.10', prefix: 24 }],
            ipv6addrsec: nil,
            ipv6addr: [{ ipaddress: '2001:db8::2', prefix: 32 }],
            ipv6init: 'yes',
            ipv6_autoconf: false,
            ipv6_defaultgw: [{ ipaddress: '2001:db8::1', prefix: 32 }],
            mac_address: nil,
            mask: %w(255.255.255.0),
            mtu: nil,
            state: 'up',
            type: 'dummy',
            vlan: nil,
            vlan_device: 'eth2',
            vlan_id: nil,
          }
        )
    end

    it do
      is_expected.to create_template('/etc/nmstate/eth3.yml')
        .with(
          source: 'nmstate.yml.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bonding_opts: nil,
            bond_ports: [],
            bridge: nil,
            bridge_options: nil,
            bridge_ports: [],
            device: 'eth3',
            enabled: true,
            ethtool_opts: nil,
            gateway: nil,
            interface: 'eth3',
            ipv4addresses: [
              { ipaddress: '10.1.30.20', prefix: 32 },
              { ipaddress: '10.1.30.21', prefix: 32 },
            ],
            ipv6addrsec: [
              { ipaddress: '2001:db8::4', prefix: 32 },
              { ipaddress: '2001:db8::5', prefix: 32 },
            ],
            ipv6addr: [ipaddress: '2001:db8::3', prefix: 32],
            ipv6init: 'yes',
            ipv6_autoconf: false,
            ipv6_defaultgw: [{ ipaddress: '2001:db8::1', prefix: 32 }],
            mac_address: nil,
            mask: [],
            mtu: nil,
            state: 'up',
            type: 'dummy',
            vlan: nil,
            vlan_device: 'eth3',
            vlan_id: nil,
          }
        )
    end

    it do
      is_expected.to create_template('/etc/nmstate/eth4.yml')
        .with(
          source: 'nmstate.yml.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bonding_opts: nil,
            bridge: nil,
            bridge_options: nil,
            bridge_ports: [],
            device: 'eth4',
            enabled: false,
            ethtool_opts: nil,
            gateway: nil,
            interface: 'eth4',
            ipv4addresses: [],
            ipv6addrsec: nil,
            ipv6addr: [],
            ipv6_autoconf: false,
            ipv6_defaultgw: nil,
            mac_address: nil,
            mask: [],
            mtu: nil,
            state: 'down',
            type: 'dummy',
            vlan: nil,
            vlan_device: 'eth4',
            vlan_id: nil,
          }
        )
    end

    it do
      is_expected.to create_template('/etc/nmstate/eth5.yml')
        .with(
          source: 'nmstate.yml.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bonding_opts: nil,
            bridge: nil,
            bridge_options: nil,
            bridge_ports: [],
            device: 'eth5',
            enabled: false,
            ethtool_opts: nil,
            gateway: nil,
            interface: 'eth5',
            ipv4addresses: [{ ipaddress: '10.1.30.20', prefix: 32 }],
            ipv6addrsec: nil,
            ipv6addr: [],
            ipv6init: nil,
            ipv6_autoconf: false,
            ipv6_defaultgw: nil,
            mac_address: nil,
            mask: [],
            mtu: nil,
            state: 'absent',
            type: 'dummy',
            vlan: nil,
            vlan_device: 'eth5',
            vlan_id: nil,
          }
        )
    end

    it do
      is_expected.to create_template('/etc/nmstate/eth6.yml')
        .with(
          source: 'nmstate.yml.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bonding_opts: nil,
            bond_ports: [],
            bridge: nil,
            bridge_options: nil,
            bridge_ports: [],
            device: 'eth6',
            enabled: true,
            ethtool_opts: nil,
            gateway: nil,
            interface: 'eth6',
            ipv4addresses: [],
            ipv6addrsec: nil,
            ipv6addr: [],
            ipv6init: 'yes',
            ipv6_autoconf: false,
            ipv6_defaultgw: nil,
            mac_address: nil,
            mask: [],
            mtu: nil,
            state: 'up',
            type: 'dummy',
            vlan: nil,
            vlan_device: 'eth6',
            vlan_id: nil,
          }
        )
    end

    it do
      is_expected.to create_template('/etc/nmstate/bond0.yml')
        .with(
          source: 'nmstate.yml.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bonding_opts: { lacp_rate: 0, miimon: 100, mode: 4 },
            bond_ports: [],
            bridge: nil,
            bridge_options: nil,
            bridge_ports: [],
            device: 'bond0',
            enabled: true,
            ethtool_opts: nil,
            gateway: nil,
            interface: 'bond0',
            ipv4addresses: [{ ipaddress: '172.16.20.10', prefix: 24 }],
            ipv6addrsec: nil,
            ipv6addr: [],
            ipv6init: nil,
            ipv6_autoconf: false,
            ipv6_defaultgw: nil,
            mac_address: nil,
            mask: %w(255.255.255.0),
            mtu: nil,
            state: 'up',
            type: nil,
            vlan: nil,
            vlan_device: 'bond0',
            vlan_id: nil,
          }
        )
    end

    it do
      is_expected.to create_template('/etc/nmstate/eth1.172.yml')
        .with(
          source: 'nmstate.yml.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bonding_opts: nil,
            bond_ports: [],
            bridge: 'br172',
            bridge_options: nil,
            bridge_ports: [],
            device: 'eth1.172',
            enabled: true,
            ethtool_opts: nil,
            gateway: nil,
            interface: 'eth1.172',
            ipv4addresses: [],
            ipv6addrsec: nil,
            ipv6addr: [],
            ipv6init: nil,
            ipv6_autoconf: false,
            ipv6_defaultgw: nil,
            mac_address: nil,
            mask: [],
            mtu: nil,
            state: 'up',
            type: nil,
            vlan: 'yes',
            vlan_device: 'eth1',
            vlan_id: '172',
          }
        )
    end

    it do
      is_expected.to create_template('/etc/nmstate/br172.yml')
        .with(
          source: 'nmstate.yml.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bonding_opts: nil,
            bond_ports: [],
            bridge: nil,
            bridge_options: nil,
            bridge_ports: %w(eth1.172),
            device: 'br172',
            enabled: true,
            ethtool_opts: nil,
            gateway: nil,
            interface: 'br172',
            ipv4addresses: [],
            ipv6addrsec: nil,
            ipv6addr: [],
            ipv6init: nil,
            ipv6_autoconf: false,
            ipv6_defaultgw: nil,
            mac_address: nil,
            mask: [],
            mtu: nil,
            state: 'up',
            type: 'linux-bridge',
            vlan: nil,
            vlan_device: 'br172',
            vlan_id: nil,
          }
        )
    end

    it do
      is_expected.to create_template('/etc/nmstate/br42.yml')
        .with(
          source: 'nmstate.yml.erb',
          cookbook: 'osl-resources',
          mode: '0640',
          variables: {
            bonding_opts: nil,
            bond_ports: [],
            bridge: nil,
            bridge_options: { stp: { enabled: false, 'forward-delay': 2 } },
            bridge_ports: %w(eno1.42),
            device: 'br42',
            enabled: true,
            ethtool_opts: nil,
            gateway: nil,
            interface: 'br42',
            ipv4addresses: [{ ipaddress: '192.168.42.1', prefix: 24 }],
            ipv6addrsec: nil,
            ipv6addr: [],
            ipv6init: nil,
            ipv6_autoconf: false,
            ipv6_defaultgw: nil,
            mac_address: nil,
            mask: %w(255.255.255.0),
            mtu: nil,
            state: 'up',
            type: 'linux-bridge',
            vlan: nil,
            vlan_device: 'br42',
            vlan_id: nil,
          }
        )
    end

    it do
      is_expected.to render_file('/etc/nmstate/eth1.yml').with_content(
        <<~EOF
            # nmstate config file written by Chef
            interfaces:
              - name: eth1
                type: dummy
                state: up
                ipv4:
                  dhcp: false
                  enabled: false
                  address: []
                ipv6:
                  dhcp: false
                  autoconf: false
                  enabled: false
                  address: []
          EOF
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/eth2.yml').with_content(
        <<~EOF
       # nmstate config file written by Chef
       interfaces:
         - name: eth2
           type: dummy
           state: up
           ipv4:
             dhcp: false
             enabled: true
             address:
               - ip: 172.16.50.10
                 prefix-length: 24
           ipv6:
             dhcp: false
             autoconf: false
             enabled: true
             address:
               - ip: "2001:db8::2"
                 prefix-length: 32
       routes:
         config:
           - destination: ::/0
             metric: 100
             next-hop-address: "2001:db8::1"
             next-hop-interface: eth2
        EOF
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/eth3.yml').with_content(
        <<~EOF
          # nmstate config file written by Chef
          interfaces:
            - name: eth3
              type: dummy
              state: up
              ipv4:
                dhcp: false
                enabled: true
                address:
                  - ip: 10.1.30.20
                    prefix-length: 32
                  - ip: 10.1.30.21
                    prefix-length: 32
              ipv6:
                dhcp: false
                autoconf: false
                enabled: true
                address:
                  - ip: "2001:db8::3"
                    prefix-length: 32
                  - ip: "2001:db8::4"
                    prefix-length: 32
                  - ip: "2001:db8::5"
                    prefix-length: 32
          routes:
            config:
              - destination: ::/0
                metric: 100
                next-hop-address: "2001:db8::1"
                next-hop-interface: eth3
        EOF
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/eth4.yml').with_content(
        <<~EOF
          # nmstate config file written by Chef
          interfaces:
            - name: eth4
              type: dummy
              state: down
              ipv4:
                dhcp: false
                enabled: false
                address: []
              ipv6:
                dhcp: false
                autoconf: false
                enabled: false
                address: []
         EOF
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/eth5.yml').with_content(
        <<~EOF
          # nmstate config file written by Chef
          interfaces:
            - name: eth5
              type: dummy
              state: absent
              ipv4:
                dhcp: false
                enabled: false
                address:
                  - ip: 10.1.30.20
                    prefix-length: 32
              ipv6:
                dhcp: false
                autoconf: false
                enabled: false
                address: []
        EOF
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/eth6.yml').with_content(
        <<~EOF
          # nmstate config file written by Chef
          interfaces:
            - name: eth6
              type: dummy
              state: up
              ipv4:
                dhcp: false
                enabled: false
                address: []
              ipv6:
                dhcp: false
                autoconf: false
                enabled: false
                address: []
        EOF
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/bond0.yml').with_content(
        <<~EOF
          # nmstate config file written by Chef
          interfaces:
            - name: bond0
              type: bond
              state: up
              ipv4:
                dhcp: false
                enabled: true
                address:
                  - ip: 172.16.20.10
                    prefix-length: 24
              ipv6:
                dhcp: false
                autoconf: false
                enabled: false
                address: []
              link-aggregation:
                mode: 4
                options:
                  miimon: 100
                  lacp_rate: 0
                port:
        EOF
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/br172.yml').with_content(
        <<~EOF
          # nmstate config file written by Chef
          interfaces:
            - name: br172
              type: linux-bridge
              state: up
              ipv4:
                dhcp: false
                enabled: false
                address: []
              ipv6:
                dhcp: false
                autoconf: false
                enabled: false
                address: []
              bridge:
                port:
                  - name: eth1.172
        EOF
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/br42.yml').with_content(
        <<~EOF
          # nmstate config file written by Chef
          interfaces:
            - name: br42
              type: linux-bridge
              state: up
              ipv4:
                dhcp: false
                enabled: true
                address:
                  - ip: 192.168.42.1
                    prefix-length: 24
              ipv6:
                dhcp: false
                autoconf: false
                enabled: false
                address: []
              bridge:
                options:
                  stp:
                    enabled: false
                    forward-delay: 2
                port:
                  - name: eno1.42
        EOF
      )
    end

    it do
      is_expected.to render_file('/etc/nmstate/eth1.172.yml').with_content(
        <<~EOF
          # nmstate config file written by Chef
          interfaces:
            - name: eth1.172
              type: vlan
              state: up
              ipv4:
                dhcp: false
                enabled: false
                address: []
              ipv6:
                dhcp: false
                autoconf: false
                enabled: false
                address: []
              vlan:
                base-iface: eth1
                id: 172
        EOF
      )
    end

    %w(
      eth1
      eth2
      eth3
      eth4
      eth5
      eth6
      bond0
      eth1.172
      br172
      br42
    ).each do |i|
      it do
        expect(chef_run.template("/etc/nmstate/#{i}.yml")).to \
          notify("execute[nmstatectl apply -q /etc/nmstate/#{i}.yml]").to(:run).immediately
      end
    end
  end
end
