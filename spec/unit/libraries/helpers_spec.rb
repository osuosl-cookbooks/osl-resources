require_relative '../../spec_helper'
require_relative '../../../libraries/helpers'

RSpec.describe OSLResources::Cookbook::Helpers do
  class DummyClass < Chef::Node
    include OSLResources::Cookbook::Helpers
  end

  subject { DummyClass.new }

  describe '#osl_local_ipv4?' do
    it 'local IPv4 address' do
      allow(subject).to receive(:[]).with('ipaddress').and_return('140.211.166.130')
      expect(subject.osl_local_ipv4?).to eq true
    end
    it 'external IPv4 address' do
      allow(subject).to receive(:[]).with('ipaddress').and_return('216.165.191.54')
      expect(subject.osl_local_ipv4?).to eq false
    end
  end

  describe '#osl_local_ipv6?' do
    it 'local IPv6 address' do
      allow(subject).to receive(:[]).with('ip6address').and_return('2605:bc80:3010::130')
      expect(subject.osl_local_ipv6?).to eq true
    end
    it 'external IPv6 address' do
      allow(subject).to receive(:[]).with('ip6address').and_return('2600:3402:600:24::154')
      expect(subject.osl_local_ipv6?).to eq false
    end
  end

  # These take primitives rather than reading new_resource.
  describe 'osl_fakenic helpers' do
    subject { DummyClass.new }

    describe '#osl_fakenic_unit_name' do
      it { expect(subject.send(:osl_fakenic_unit_name, 'eth1')).to eq 'osl-fakenic-eth1.service' }

      # A dot is legal in a unit name and must survive, since VLAN-shaped
      # interface names are passed straight through by several consumers.
      it { expect(subject.send(:osl_fakenic_unit_name, 'eth1.10')).to eq 'osl-fakenic-eth1.10.service' }

      it 'folds characters systemd will not accept' do
        expect(subject.send(:osl_fakenic_unit_name, 'br-ex/0')).to eq 'osl-fakenic-br-ex-0.service'
      end
    end

    describe '#osl_fakenic_ip_path' do
      it 'uses the resolved path' do
        allow(subject).to receive(:which).with('ip').and_return('/usr/bin/ip')
        expect(subject.send(:osl_fakenic_ip_path)).to eq '/usr/bin/ip'
      end

      it 'falls back when ip is not on PATH' do
        allow(subject).to receive(:which).with('ip').and_return(false)
        expect(subject.send(:osl_fakenic_ip_path)).to eq '/usr/sbin/ip'
      end
    end

    describe '#osl_fakenic_unit_path' do
      it do
        expect(subject.send(:osl_fakenic_unit_path, 'eth1'))
          .to eq '/etc/systemd/system/osl-fakenic-eth1.service'
      end
    end

    describe '#osl_fakenic_unit_content' do
      # Ordered before NetworkManager so the device exists before anything
      # tries to activate a profile against it.
      it 'orders itself ahead of the network stack' do
        expect(subject.send(:osl_fakenic_unit_content, interface: 'eth1', ip_path: '/usr/sbin/ip'))
          .to match(/^Before=network-pre\.target NetworkManager\.service$/)
      end

      # `-` swallows EEXIST when NetworkManager created the device first.
      it 'tolerates the device already existing' do
        expect(subject.send(:osl_fakenic_unit_content, interface: 'eth1', ip_path: '/usr/sbin/ip'))
          .to match(%r{^ExecStart=-/usr/sbin/ip link add name eth1 type dummy$})
      end

      it 'stays inactive-safe with no ExecStop' do
        expect(subject.send(:osl_fakenic_unit_content, interface: 'eth1', ip_path: '/usr/sbin/ip')).to_not match(/ExecStop/)
      end

      # replace, not add, so a rerun against a configured device is not an error.
      it 'replaces addresses rather than adding them' do
        content = subject.send(:osl_fakenic_unit_content, interface: 'eth1', ip_path: '/usr/sbin/ip', ip4: %w(10.0.0.1/24), ip6: %w(fe80::1/64))
        expect(content).to match(%r{^ExecStart=/usr/sbin/ip addr replace 10\.0\.0\.1/24 dev eth1$})
        expect(content).to match(%r{^ExecStart=/usr/sbin/ip -6 addr replace fe80::1/64 dev eth1$})
      end

      # Setting a MAC on a live link is avoided by ordering it before `up`.
      it 'sets the MAC and multicast before bringing the link up' do
        content = subject.send(
          :osl_fakenic_unit_content,
          interface: 'eth1', ip_path: '/usr/sbin/ip', mac_address: '00:11:22:33:44:55', multicast: true
        )
        expect(content.index('address 00:11:22:33:44:55')).to be < content.index('link set dev eth1 up')
        expect(content.index('multicast on')).to be < content.index('link set dev eth1 up')
      end

      it 'is parseable as a unit file' do
        expect { IniParse.parse(subject.send(:osl_fakenic_unit_content, interface: 'eth1', ip_path: '/usr/sbin/ip')) }.to_not raise_error
      end
    end
  end

  # These read their inputs off new_resource, so stub it rather than converge.
  describe 'osl_ifconfig helpers' do
    let(:attrs) { {} }
    let(:resource) do
      double(
        {
          bonding_opts: nil, bridge: nil, device: 'eth0', ipv6addr: [], ipv6addrsec: nil,
          ipv6_autoconf: nil, ipv6_defaultgw: nil, ipv6init: nil, mask: [], master: nil,
          onboot: 'yes', type: nil
        }.merge(attrs)
      )
    end

    subject do
      DummyClass.new.tap { |d| allow(d).to receive(:new_resource).and_return(resource) }
    end

    describe '#nmstate_ipaddrs' do
      context 'with a matching mask' do
        let(:attrs) { { mask: %w(255.255.255.0) } }

        it 'resolves the prefix from the mask' do
          expect(subject.send(:nmstate_ipaddrs, %w(10.1.30.20)))
            .to eq [{ ipaddress: '10.1.30.20', prefix: 24 }]
        end
      end

      context 'with one mask and several addresses' do
        let(:attrs) { { mask: %w(255.255.255.0) } }

        it 'broadcasts the single mask' do
          expect(subject.send(:nmstate_ipaddrs, %w(10.1.30.20 10.1.30.21)))
            .to eq [{ ipaddress: '10.1.30.20', prefix: 24 }, { ipaddress: '10.1.30.21', prefix: 24 }]
        end
      end

      context 'with a CIDR suffix on the address' do
        let(:attrs) { { mask: %w(255.255.0.0) } }

        it 'prefers the CIDR over the mask' do
          expect(subject.send(:nmstate_ipaddrs, %w(10.1.30.20/24)))
            .to eq [{ ipaddress: '10.1.30.20', prefix: 24 }]
        end
      end

      it 'resolves IPv6 from its CIDR suffix' do
        expect(subject.send(:nmstate_ipaddrs, %w(2001:db8::2/64)))
          .to eq [{ ipaddress: '2001:db8::2', prefix: 64 }]
      end

      # IPAddr's default /32 leaves the interface up but unable to reach its
      # gateway.
      it 'raises rather than inventing a /32' do
        expect { subject.send(:nmstate_ipaddrs, %w(10.1.30.20)) }
          .to raise_error(RuntimeError, /no mask or CIDR prefix/)
      end

      # ifcfg-rh reads a bare IPV6ADDR as /64; rendering /128 on nmstate left
      # the v6 gateway unreachable.
      it 'defaults a bare IPv6 address to /64' do
        expect(Chef::Log).to receive(:warn).with(%r{no CIDR prefix.*assuming /64})
        expect(subject.send(:nmstate_ipaddrs, %w(2001:db8::2)))
          .to eq [{ ipaddress: '2001:db8::2', prefix: 64 }]
      end

      it 'does not warn when the IPv6 prefix is explicit' do
        expect(Chef::Log).to_not receive(:warn)
        expect(subject.send(:nmstate_ipaddrs, %w(2001:db8::2/56)))
          .to eq [{ ipaddress: '2001:db8::2', prefix: 56 }]
      end
    end

    describe '#nmstate_bonding_opts' do
      context 'with numeric values' do
        let(:attrs) { { bonding_opts: 'mode=4 miimon=100 lacp_rate=0' } }

        it 'keeps them as Integers' do
          expect(subject.send(:nmstate_bonding_opts))
            .to eq(mode: 4, miimon: 100, lacp_rate: 0)
        end
      end

      # to_i turned active-backup into 0, so a failover pair came up
      # round-robin.
      context 'with named values' do
        let(:attrs) do
          { bonding_opts: 'mode=802.3ad xmit_hash_policy=layer3+4 lacp_rate=fast primary=eth0' }
        end

        it 'preserves them verbatim' do
          expect(subject.send(:nmstate_bonding_opts))
            .to eq(mode: '802.3ad', xmit_hash_policy: 'layer3+4', lacp_rate: 'fast', primary: 'eth0')
        end
      end

      context 'with active-backup' do
        let(:attrs) { { bonding_opts: 'mode=active-backup miimon=100' } }

        it 'does not collapse the mode to 0' do
          expect(subject.send(:nmstate_bonding_opts)).to eq(mode: 'active-backup', miimon: 100)
        end
      end

      it 'returns nil when unset' do
        expect(subject.send(:nmstate_bonding_opts)).to be_nil
      end
    end

    describe '#nmstate_ipv6_enabled?' do
      it 'is false with no stated IPv6 intent' do
        expect(subject.send(:nmstate_ipv6_enabled?)).to eq false
      end

      context 'with ipv6init' do
        let(:attrs) { { ipv6init: 'yes' } }
        it { expect(subject.send(:nmstate_ipv6_enabled?)).to eq true }
      end

      context 'with autoconf' do
        let(:attrs) { { ipv6_autoconf: 'yes' } }
        it { expect(subject.send(:nmstate_ipv6_enabled?)).to eq true }
      end

      context 'with a static address' do
        let(:attrs) { { ipv6addr: %w(2001:db8::2/64) } }
        it { expect(subject.send(:nmstate_ipv6_enabled?)).to eq true }
      end

      context 'with a default gateway' do
        let(:attrs) { { ipv6_defaultgw: '2001:db8::1' } }
        it { expect(subject.send(:nmstate_ipv6_enabled?)).to eq true }
      end
    end

    describe '#nmstate_gateway_addr' do
      it 'strips a prefix ifcfg-rh and nmstate both reject' do
        expect(subject.send(:nmstate_gateway_addr, '2001:db8::1/64')).to eq '2001:db8::1'
      end

      it 'passes a bare address through' do
        expect(subject.send(:nmstate_gateway_addr, '10.0.0.1')).to eq '10.0.0.1'
      end

      it 'returns nil when unset' do
        expect(subject.send(:nmstate_gateway_addr, nil)).to be_nil
      end
    end

    describe '#nmstate_controller' do
      context 'from bridge' do
        let(:attrs) { { bridge: 'br0' } }
        it { expect(subject.send(:nmstate_controller)).to eq 'br0' }
      end

      context 'from master' do
        let(:attrs) { { master: 'bond0' } }
        it { expect(subject.send(:nmstate_controller)).to eq 'bond0' }
      end

      it { expect(subject.send(:nmstate_controller)).to be_nil }
    end

    describe '#nmstate_vlan_device and #nmstate_vlan_id' do
      context 'with a dotted name' do
        let(:attrs) { { device: 'eth1.172' } }
        it { expect(subject.send(:nmstate_vlan_device)).to eq 'eth1' }
        it { expect(subject.send(:nmstate_vlan_id)).to eq '172' }
      end

      context 'with an undotted name' do
        let(:attrs) { { device: 'vlan42' } }
        it { expect(subject.send(:nmstate_vlan_id)).to be_nil }
      end
    end

    describe '#nmstate_state' do
      it { expect(subject.send(:nmstate_state)).to eq 'up' }

      context 'with onboot no' do
        let(:attrs) { { onboot: 'no' } }
        it { expect(subject.send(:nmstate_state)).to eq 'down' }
      end
    end

    describe '#ifconfig_type' do
      context 'linux-bridge' do
        let(:attrs) { { type: 'linux-bridge' } }
        it { expect(subject.send(:ifconfig_type)).to eq 'Bridge' }
      end

      context 'bond' do
        let(:attrs) { { type: 'bond' } }
        it { expect(subject.send(:ifconfig_type)).to eq 'Bond' }
      end

      # nmstate infers the bond type from bonding_opts; ifcfg must be told.
      context 'bonding_opts with no explicit type' do
        let(:attrs) { { bonding_opts: 'mode=4 miimon=100' } }
        it { expect(subject.send(:ifconfig_type)).to eq 'Bond' }
      end

      it { expect(subject.send(:ifconfig_type)).to be_nil }
    end
  end
end
