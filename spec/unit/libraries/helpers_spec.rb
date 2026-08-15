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
