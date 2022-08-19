require_relative '../../spec_helper'

describe 'osl_ifconfig' do
  before do
    stub_command('ip link show dev eth4 | grep \'UP\'').and_return(false)
    stub_command('ip link show dev eth4 | grep \'DOWN\'').and_return(false)
  end

  recipe do
    osl_ifconfig 'eth1' do
      target ''
      bootproto 'none'
      nm_controlled 'no'
      device 'eth1'
      type 'dummy'
    end

    osl_ifconfig 'eth2' do
      device 'eth2'
      target '172.16.50.10'
      mask '255.255.255.0'
      network '172.16.50.0'
      bootproto 'static'
      onboot 'yes'
      ipv6init 'yes'
      ipv6addr 'fe80::2/64'
      ipv6_defaultgw 'fe80::1/64'
      type 'dummy'
    end

    osl_ifconfig 'eth3' do
      device 'eth3'
      target %w(
        10.1.30.20
        10.1.30.21
      )
      onboot 'yes'
      ipv6init 'yes'
      ipv6addr 'fe80::3/64'
      ipv6addrsec %w(
        fe80::4/64
        fe80::5/64
      )
      ipv6_defaultgw 'fe80::1/64'
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
      target '10.1.30.20'
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
      target '172.16.20.10'
      mask '255.255.255.0'
      network '172.16.20.0'
      device 'bond0'
      bootproto 'static'
      bonding_opts 'mode=4 miimon=100 lacp_rate=0'
      onboot 'yes'
    end

    osl_ifconfig 'br172' do
      target ''
      device 'br172'
      onboot 'yes'
      bootproto 'none'
      nm_controlled 'no'
      delay '0'
    end

    osl_ifconfig 'eth1vlan172' do
      target ''
      device 'eth1.172'
      onboot 'yes'
      bootproto 'none'
      nm_controlled 'no'
      userctl 'no'
      vlan 'yes'
      bridge 'br172'
    end
  end

  context 'centos 7' do
    platform 'centos', '7'
    cached(:subject) { chef_run }
    step_into :osl_ifconfig

    it do
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-eth1')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          owner: 'root',
          group: 'root',
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
            ipv6addr: nil,
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: nil,
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: '',
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
          owner: 'root',
          group: 'root',
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
            ipv6addr: 'fe80::2/64',
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: 'fe80::1/64',
            ipv6init: 'yes',
            mask: '255.255.255.0',
            master: nil,
            metric: nil,
            mtu: nil,
            network: '172.16.50.0',
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: '172.16.50.10',
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
          owner: 'root',
          group: 'root',
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
            ipv6addr: 'fe80::3/64',
            ipv6addrsec: %w(
              fe80::4/64
              fe80::5/64
            ),
            ipv6_autoconf: nil,
            ipv6_defaultgw: 'fe80::1/64',
            ipv6init: 'yes',
            mask: nil,
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'yes',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: %w(
              10.1.30.20
              10.1.30.21
            ),
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
          owner: 'root',
          group: 'root',
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
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-eth6')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          owner: 'root',
          group: 'root',
          mode: '0640',
          variables: {
            bcast: nil,
            bonding_opts: nil,
            bootproto: 'static',
            bridge: nil,
            defroute: nil,
            delay: nil,
            device: 'eth6',
            ethtool_opts: nil,
            gateway: nil,
            hwaddr: nil,
            ipv6addr: nil,
            ipv6addrsec: nil,
            ipv6_autoconf: 'no',
            ipv6_defaultgw: nil,
            ipv6init: 'yes',
            mask: nil,
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: 'eth6',
            type: 'dummy',
            userctl: nil,
            vlan: nil,
          }
        )
    end
    it do
      expect(chef_run.template('/etc/sysconfig/network-scripts/ifcfg-eth6')).to \
        notify('execute[ifup eth6]').immediately
    end

    it do
      expect(chef_run).to nothing_execute('ifup eth6')
    end

    it do
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-bond0')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          owner: 'root',
          group: 'root',
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
            ipv6addr: nil,
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: '255.255.255.0',
            master: nil,
            metric: nil,
            mtu: nil,
            network: '172.16.20.0',
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: '172.16.20.10',
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
          owner: 'root',
          group: 'root',
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
            ipv6addr: nil,
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: nil,
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: '',
            type: nil,
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
          owner: 'root',
          group: 'root',
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
            ipv6addr: nil,
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: nil,
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: '',
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
  end

  context 'centos 8' do
    platform 'centos', '8'
    cached(:subject) { chef_run }
    step_into :osl_ifconfig

    it do
      is_expected.to create_template('/etc/sysconfig/network-scripts/ifcfg-eth1')
        .with(
          source: 'ifcfg.conf.erb',
          cookbook: 'osl-resources',
          owner: 'root',
          group: 'root',
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
            ipv6addr: nil,
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: nil,
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: '',
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
          owner: 'root',
          group: 'root',
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
            ipv6addr: 'fe80::2/64',
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: 'fe80::1/64',
            ipv6init: 'yes',
            mask: '255.255.255.0',
            master: nil,
            metric: nil,
            mtu: nil,
            network: '172.16.50.0',
            nm_controlled: 'yes',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: '172.16.50.10',
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
          owner: 'root',
          group: 'root',
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
            ipv6addr: 'fe80::3/64',
            ipv6addrsec: %w(
              fe80::4/64
              fe80::5/64
            ),
            ipv6_autoconf: nil,
            ipv6_defaultgw: 'fe80::1/64',
            ipv6init: 'yes',
            mask: nil,
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'yes',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: %w(
              10.1.30.20
              10.1.30.21
            ),
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
          owner: 'root',
          group: 'root',
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
          owner: 'root',
          group: 'root',
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
            ipv6addr: nil,
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: '255.255.255.0',
            master: nil,
            metric: nil,
            mtu: nil,
            network: '172.16.20.0',
            nm_controlled: 'yes',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: '172.16.20.10',
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
          owner: 'root',
          group: 'root',
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
            ipv6addr: nil,
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: nil,
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: '',
            type: nil,
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
          owner: 'root',
          group: 'root',
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
            ipv6addr: nil,
            ipv6addrsec: nil,
            ipv6_autoconf: nil,
            ipv6_defaultgw: nil,
            ipv6init: nil,
            mask: nil,
            master: nil,
            metric: nil,
            mtu: nil,
            network: nil,
            nm_controlled: 'no',
            onboot: 'yes',
            onparent: nil,
            peerdns: 'no',
            slave: nil,
            target: '',
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
  end
end
