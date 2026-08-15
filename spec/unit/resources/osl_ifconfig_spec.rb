require_relative '../../spec_helper'
require 'yaml'

# A right-looking `variables` hash can render a wrong YAML key, so these
# assert rendered content rather than the hash.
describe 'osl_ifconfig' do
  # Guards are Ruby blocks now, not shelled-out strings. "Not admin up" is the
  # interesting default: it exercises the repair path.
  before do
    allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(false)
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
      mask '255.255.255.0'
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

    osl_ifconfig 'eth6' do
      device 'eth6'
      onboot 'yes'
      bootproto 'static'
      ipv6init 'yes'
      ipv6_autoconf 'no'
      type 'dummy'
    end

    # SLAAC intent: nmstate needs dhcp and autoconf on together.
    osl_ifconfig 'eth7' do
      device 'eth7'
      onboot 'yes'
      bootproto 'static'
      ipv6init 'yes'
      ipv6_autoconf 'yes'
      type 'dummy'
    end

    # mtu + hwaddr + an IPv4 gateway with a non-default metric, none of which
    # had any coverage before.
    osl_ifconfig 'eth8' do
      device 'eth8'
      type 'dummy'
      mtu '9000'
      hwaddr '00:11:22:33:44:55'
      ipv4addr '10.9.9.9/24'
      gateway '10.9.9.1'
      metric '200'
    end

    osl_ifconfig 'bond0' do
      ipv4addr '172.16.20.10'
      mask '255.255.255.0'
      network '172.16.20.0'
      device 'bond0'
      bootproto 'static'
      bonding_opts 'mode=4 miimon=100 lacp_rate=0'
      bond_ports %w(eth1 eth2)
      onboot 'yes'
    end

    # Named bonding option values must survive verbatim.
    osl_ifconfig 'bond1' do
      device 'bond1'
      bonding_opts 'mode=active-backup miimon=100 primary=eth1'
      bond_ports %w(eth1 eth2)
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

    osl_ifconfig 'br43' do
      type 'linux-bridge'
      bridge_ports %w(eno1.43)
      bridge_options(
        'stp' => { 'enabled' => false, 'forward-delay' => 2 }
      )
      onboot 'yes'
      bootproto 'static'
      ipv4addr '192.168.43.1'
      mask '255.255.255.0'
    end

    # delay > 0: STP on with that forward delay, unlike delay '0' (STP off).
    osl_ifconfig 'br45' do
      type 'linux-bridge'
      bridge_ports %w(eno1.45)
      onboot 'yes'
      bootproto 'none'
      delay '4'
    end
  end

  ALL_DEVICES = %w(
    eth1 eth2 eth3 eth6 eth7 eth8 bond0 bond1 eth1.172 br172 br42 br43 br45
  ).freeze

  context 'almalinux 8' do
    platform 'almalinux', '8'
    cached(:subject) { chef_run }
    step_into :osl_ifconfig

    it { is_expected.to install_package('network-scripts') }
    it { is_expected.to create_file('/etc/sysconfig/disable-deprecation-warnings') }

    # The paths must be mutually exclusive: EL8 has no nmstatectl.
    it { is_expected.to_not install_package('nmstate') }
    it { is_expected.to_not create_directory('/etc/nmstate') }
    it { is_expected.to_not create_template('/etc/nmstate/eth1.yml') }

    {
      'eth1' => <<~EOF,
        # ifcfg config file written by Chef
        BOOTPROTO=none
        DEVICE=eth1
        NM_CONTROLLED=no
        ONBOOT=yes
        PEERDNS=no
        TYPE=dummy
      EOF
      'eth2' => <<~EOF,
        # ifcfg config file written by Chef
        BOOTPROTO=static
        DEVICE=eth2
        IPV6ADDR=2001:db8::2/32
        IPV6_DEFAULTGW=2001:db8::1
        IPV6INIT=yes
        NETMASK=255.255.255.0
        NETWORK=172.16.50.0
        NM_CONTROLLED=yes
        ONBOOT=yes
        PEERDNS=no
        IPADDR=172.16.50.10
        TYPE=dummy
      EOF
      'eth3' => <<~EOF,
        # ifcfg config file written by Chef
        DEVICE=eth3
        IPV6ADDR=2001:db8::3/32
        IPV6ADDR_SECONDARIES='2001:db8::4/32 2001:db8::5/32'
        IPV6_DEFAULTGW=2001:db8::1
        IPV6INIT=yes
        NETMASK=255.255.255.0
        NETMASK1=255.255.255.0
        NM_CONTROLLED=yes
        ONBOOT=yes
        PEERDNS=no
        IPADDR=10.1.30.20
        IPADDR1=10.1.30.21
        TYPE=dummy
      EOF
      'eth8' => <<~EOF,
        # ifcfg config file written by Chef
        DEVICE=eth8
        GATEWAY=10.9.9.1
        HWADDR=00:11:22:33:44:55
        METRIC=200
        MTU=9000
        NM_CONTROLLED=yes
        ONBOOT=yes
        PEERDNS=no
        IPADDR=10.9.9.9
        PREFIX=24
        TYPE=dummy
      EOF
      'bond0' => <<~EOF,
        # ifcfg config file written by Chef
        BONDING_OPTS="mode=4 miimon=100 lacp_rate=0"
        BONDING_MASTER=yes
        BOOTPROTO=static
        DEVICE=bond0
        NETMASK=255.255.255.0
        NETWORK=172.16.20.0
        NM_CONTROLLED=yes
        ONBOOT=yes
        PEERDNS=no
        IPADDR=172.16.20.10
        TYPE=Bond
      EOF
      'eth1.172' => <<~EOF,
        # ifcfg config file written by Chef
        BOOTPROTO=none
        BRIDGE=br172
        DEVICE=eth1.172
        NM_CONTROLLED=no
        ONBOOT=yes
        PEERDNS=no
        USERCTL=no
        VLAN=yes
      EOF
      'br172' => <<~EOF,
        # ifcfg config file written by Chef
        BOOTPROTO=none
        DELAY=0
        DEVICE=br172
        NM_CONTROLLED=no
        ONBOOT=yes
        PEERDNS=no
        TYPE=Bridge
      EOF
    }.each do |device, content|
      it "renders ifcfg-#{device}" do
        is_expected.to render_file("/etc/sysconfig/network-scripts/ifcfg-#{device}").with_content(content)
      end
    end

    # An address-less interface must not get a bare `IPV6ADDR=`.
    %w(eth1 eth6 br172).each do |device|
      it "does not emit an empty IPV6ADDR for #{device}" do
        is_expected.to_not render_file("/etc/sysconfig/network-scripts/ifcfg-#{device}")
          .with_content(/^IPV6ADDR=$/)
      end
    end

    # A bond master needs TYPE/BONDING_MASTER regardless of what it is named.
    it 'infers Bond type from bonding_opts alone' do
      is_expected.to render_file('/etc/sysconfig/network-scripts/ifcfg-bond1')
        .with_content(/^TYPE=Bond$/).with_content(/^BONDING_MASTER=yes$/)
    end

    ALL_DEVICES.each do |device|
      it "brings up #{device} when the link is down" do
        is_expected.to run_execute("bring up #{device}")
          .with(command: "ifup #{device} && ip link set dev #{device} up")
      end

      it "notifies ifup on an ifcfg change for #{device}" do
        expect(chef_run.template("/etc/sysconfig/network-scripts/ifcfg-#{device}")).to \
          notify("execute[ifup #{device}]").to(:run).immediately
      end
    end
  end

  # AlmaLinux 10 is a kitchen platform but had no unit coverage at all.
  %w(9 10).each do |version|
    context "almalinux #{version}" do
      platform 'almalinux', version
      cached(:subject) { chef_run }
      step_into :osl_ifconfig

      it { is_expected.to install_package('nmstate') }
      it { is_expected.to create_directory('/etc/nmstate') }
      it { is_expected.to_not install_package('network-scripts') }
      it { is_expected.to_not create_template('/etc/sysconfig/network-scripts/ifcfg-eth1') }

      {
        'eth1' => <<~EOF,
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
        'eth2' => <<~EOF,
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
              - destination: "::/0"
                metric: 100
                next-hop-address: "2001:db8::1"
                next-hop-interface: eth2
        EOF
        'eth3' => <<~EOF,
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
                    prefix-length: 24
                  - ip: 10.1.30.21
                    prefix-length: 24
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
              - destination: "::/0"
                metric: 100
                next-hop-address: "2001:db8::1"
                next-hop-interface: eth3
        EOF
        'eth6' => <<~EOF,
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
                enabled: true
                address: []
        EOF
        'eth7' => <<~EOF,
          # nmstate config file written by Chef
          interfaces:
            - name: eth7
              type: dummy
              state: up
              ipv4:
                dhcp: false
                enabled: false
                address: []
              ipv6:
                dhcp: true
                autoconf: true
                enabled: true
                address: []
        EOF
        'eth8' => <<~EOF,
          # nmstate config file written by Chef
          interfaces:
            - name: eth8
              type: dummy
              state: up
              mtu: 9000
              mac-address: 00:11:22:33:44:55
              ipv4:
                dhcp: false
                enabled: true
                address:
                  - ip: 10.9.9.9
                    prefix-length: 24
              ipv6:
                dhcp: false
                autoconf: false
                enabled: false
                address: []
          routes:
            config:
              - destination: 0.0.0.0/0
                metric: 200
                next-hop-address: 10.9.9.1
                next-hop-interface: eth8
        EOF
        'bond0' => <<~EOF,
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
                  - eth1
                  - eth2
        EOF
        'bond1' => <<~EOF,
          # nmstate config file written by Chef
          interfaces:
            - name: bond1
              type: bond
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
              link-aggregation:
                mode: active-backup
                options:
                  miimon: 100
                  primary: eth1
                port:
                  - eth1
                  - eth2
        EOF
        'eth1.172' => <<~EOF,
          # nmstate config file written by Chef
          interfaces:
            - name: eth1.172
              type: vlan
              state: up
              controller: br172
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
            - name: br172
              type: linux-bridge
              state: up
        EOF
        'br172' => <<~EOF,
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
                options:
                  stp:
                    enabled: false
                port:
                  - name: eth1.172
        EOF
        'br42' => <<~EOF,
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
        'br43' => <<~EOF,
          # nmstate config file written by Chef
          interfaces:
            - name: br43
              type: linux-bridge
              state: up
              ipv4:
                dhcp: false
                enabled: true
                address:
                  - ip: 192.168.43.1
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
                  - name: eno1.43
        EOF
        'br45' => <<~EOF,
          # nmstate config file written by Chef
          interfaces:
            - name: br45
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
                options:
                  stp:
                    enabled: true
                    forward-delay: 4
                port:
                  - name: eno1.45
        EOF
      }.each do |device, content|
        it "renders #{device}.yml" do
          is_expected.to render_file("/etc/nmstate/#{device}.yml").with_content(content)
        end
      end

      # String matching alone missed secondary addresses escaping their block.
      ALL_DEVICES.each do |device|
        it "renders parseable YAML for #{device}" do
          is_expected.to render_file("/etc/nmstate/#{device}.yml").with_content { |content|
            expect { YAML.safe_load(content) }.to_not raise_error
          }
        end

        it "notifies nmstatectl on a config change for #{device}" do
          expect(chef_run.template("/etc/nmstate/#{device}.yml")).to \
            notify("execute[nmstatectl apply -q /etc/nmstate/#{device}.yml]").to(:run).immediately
        end

        it "re-applies #{device} when the link is down" do
          is_expected.to run_execute("bring up #{device}")
            .with(command: "nmstatectl apply -q /etc/nmstate/#{device}.yml")
        end
      end
    end
  end
end

describe 'osl_ifconfig level-triggered repair' do
  platform 'almalinux', '9'
  step_into :osl_ifconfig

  recipe do
    osl_ifconfig 'eth1' do
      type 'dummy'
    end
  end

  context 'link already up' do
    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(true)
    end

    # An already-up interface must not re-apply, or enforce_idempotency fails.
    it { is_expected.to_not run_execute('bring up eth1') }
  end

  context 'link down' do
    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(false)
    end

    it { is_expected.to run_execute('bring up eth1') }
  end

  context 'onboot no' do
    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(false)
    end

    recipe do
      osl_ifconfig 'eth1' do
        type 'dummy'
        onboot 'no'
      end
    end

    # state: down -- re-applying would fight itself forever.
    it { is_expected.to_not run_execute('bring up eth1') }
    it { is_expected.to render_file('/etc/nmstate/eth1.yml').with_content(/state: down/) }
  end
end

describe 'osl_ifconfig teardown' do
  step_into :osl_ifconfig

  before do
    allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(true)
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:exist?)
      .with('/etc/sysconfig/network-scripts/ifcfg-bond0').and_return(true)
  end

  recipe do
    osl_ifconfig 'bond0' do
      bonding_opts 'mode=4 miimon=100'
      bond_ports %w(eth1 eth2)
      ipv4addr '172.16.20.10'
      mask '255.255.255.0'
      gateway '172.16.20.1'
      action :delete
    end
  end

  context 'almalinux 9' do
    platform 'almalinux', '9'
    cached(:subject) { chef_run }

    # bond_ports was omitted from :delete, raising NoMethodError on teardown.
    it { is_expected.to render_file('/etc/nmstate/bond0.yml').with_content(/state: absent/) }
    it { is_expected.to render_file('/etc/nmstate/bond0.yml').with_content(/- eth1/) }

    # nmstate rejects a route via an interface the same document marks absent.
    it { is_expected.to_not render_file('/etc/nmstate/bond0.yml').with_content(/routes:/) }

    it 'renders parseable YAML' do
      is_expected.to render_file('/etc/nmstate/bond0.yml').with_content { |content|
        expect { YAML.safe_load(content) }.to_not raise_error
      }
    end

    it { is_expected.to install_package('nmstate') }
    it { is_expected.to create_directory('/etc/nmstate') }
  end

  context 'almalinux 8' do
    platform 'almalinux', '8'
    cached(:subject) { chef_run }

    # ifdown must run before the TYPE=none stub replaces the real config.
    it { is_expected.to run_execute('ifdown bond0') }
    it { is_expected.to create_file('/etc/sysconfig/network-scripts/ifcfg-bond0') }

    it 'tears down before overwriting the config' do
      resources = chef_run.resource_collection.all_resources.map(&:to_s)
      expect(resources.index('execute[ifdown bond0]'))
        .to be < resources.index('file[/etc/sysconfig/network-scripts/ifcfg-bond0]')
    end
  end

  context 'device that was never created' do
    platform 'almalinux', '8'

    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(false)
    end

    # An unguarded ifdown aborted the whole run here.
    it { is_expected.to_not run_execute('ifdown bond0') }
  end
end

describe 'osl_ifconfig enable and disable' do
  step_into :osl_ifconfig
  platform 'almalinux', '9'

  before do
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:exist?).with('/etc/nmstate/eth4.yml').and_return(true)
  end

  context 'enable when the link is down' do
    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(false)
    end

    recipe do
      osl_ifconfig 'eth4' do
        type 'dummy'
        action :enable
      end
    end

    it { is_expected.to run_execute('nmstatectl apply -q /etc/nmstate/eth4.yml') }
  end

  context 'enable when the link is already up' do
    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(true)
    end

    recipe do
      osl_ifconfig 'eth4' do
        type 'dummy'
        action :enable
      end
    end

    it { is_expected.to_not run_execute('nmstatectl apply -q /etc/nmstate/eth4.yml') }
  end

  context 'enable with force overrides the guard' do
    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(true)
    end

    recipe do
      osl_ifconfig 'eth4' do
        type 'dummy'
        force true
        action :enable
      end
    end

    it { is_expected.to run_execute('nmstatectl apply -q /etc/nmstate/eth4.yml') }
  end

  # The documented combined form: both actions declare the same execute name.
  context 'enable and disable in one resource' do
    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(true)
    end

    recipe do
      osl_ifconfig 'eth4' do
        type 'dummy'
        action [:enable, :disable]
      end
    end

    it { expect { chef_run }.to_not raise_error }
    it { is_expected.to render_file('/etc/nmstate/eth4.yml').with_content(/state: down/) }
  end

  context 'disable only acts on an interface that is up' do
    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(false)
    end

    recipe do
      osl_ifconfig 'eth4' do
        type 'dummy'
        action :disable
      end
    end

    it { is_expected.to render_file('/etc/nmstate/eth4.yml').with_content(/state: down/) }
    it { is_expected.to_not run_execute('nmstatectl apply -q /etc/nmstate/eth4.yml') }
  end
end

describe 'osl_ifconfig validation' do
  step_into :osl_ifconfig
  platform 'almalinux', '9'

  before do
    allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(false)
  end

  context 'address with neither mask nor CIDR' do
    recipe do
      osl_ifconfig 'eth1' do
        type 'dummy'
        ipv4addr '10.1.30.20'
      end
    end

    it { expect { chef_run }.to raise_error(RuntimeError, /no mask or CIDR prefix/) }

    # A missing prefix is a silent /32 on nmstate and a classful guess on
    # ifcfg; both are wrong, so both must fail.
    context 'on the ifcfg path' do
      platform 'almalinux', '8'

      it { expect { chef_run }.to raise_error(RuntimeError, /no mask or CIDR prefix/) }
    end
  end

  # Teardown never uses the addresses, so the prefix check must not block the
  # actions that would clean up the offending config.
  %i(delete disable).each do |act|
    context "#{act} on a resource whose address has no prefix" do
      recipe do
        osl_ifconfig 'eth1' do
          type 'dummy'
          ipv4addr '10.1.30.20'
          action act
        end
      end

      it { expect { chef_run }.to_not raise_error }
    end
  end

  # ifcfg HWADDR= matches, nmstate mac-address: sets, so a stale value is
  # inert on one path and destructive on the other.
  context 'hwaddr on the nmstate path' do
    recipe do
      osl_ifconfig 'eth1' do
        type 'dummy'
        hwaddr '00:11:22:33:44:55'
      end
    end

    it 'warns that it sets rather than matches' do
      expect(Chef::Log).to receive(:warn).with(/hwaddr sets the interface MAC/)
      chef_run
    end
  end

  context 'hwaddr on the ifcfg path' do
    platform 'almalinux', '8'

    recipe do
      osl_ifconfig 'eth1' do
        type 'dummy'
        hwaddr '00:11:22:33:44:55'
      end
    end

    it 'does not warn, since HWADDR= matching is the intended use' do
      expect(Chef::Log).to_not receive(:warn).with(/hwaddr/)
      chef_run
    end
  end

  context 'fewer masks than addresses' do
    recipe do
      osl_ifconfig 'eth1' do
        type 'dummy'
        ipv4addr %w(10.1.30.20 10.2.30.20)
        mask %w(255.255.255.0 255.255.0.0 255.0.0.0)
      end
    end

    it { expect { chef_run }.to_not raise_error }
  end

  context 'vlan with an underivable id' do
    recipe do
      osl_ifconfig 'vlan42' do
        vlan 'yes'
      end
    end

    it { expect { chef_run }.to raise_error(RuntimeError, /cannot derive a VLAN id/) }
  end

  context 'bond without bonding_opts' do
    recipe do
      osl_ifconfig 'bond0' do
        type 'bond'
      end
    end

    it { expect { chef_run }.to raise_error(RuntimeError, /requires bonding_opts/) }
  end

  context 'bonding_opts without a mode' do
    recipe do
      osl_ifconfig 'bond0' do
        bonding_opts 'miimon=100'
      end
    end

    it { expect { chef_run }.to raise_error(RuntimeError, /must include mode=/) }
  end
end
