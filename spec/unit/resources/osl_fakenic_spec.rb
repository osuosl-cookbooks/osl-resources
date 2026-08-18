require_relative '../../spec_helper'

describe 'osl_fakenic' do
  platform 'almalinux'
  cached(:subject) { chef_run }
  step_into :osl_fakenic

  before do
    allow_any_instance_of(Chef::Provider).to receive(:osl_fakenic_ip_path).and_return('/usr/sbin/ip')
    stub_command('ip a show dev eth1').and_return(false)
    stub_command('ip a show dev eth2').and_return(false)
    stub_command('ip a show dev eth1 | grep UP').and_return(false)
    stub_command('ip a show dev eth2').and_return(false)
    stub_command('ip a show dev eth2 | grep UP').and_return(false)
    stub_command('ip a show dev eth2 | grep 192.168.0.1/24').and_return(false)
    stub_command('ip -6 a show dev eth2 | grep fe80::1/64').and_return(false)
    stub_command('ip a show dev eth2 | grep MULTICAST').and_return(false)
    stub_command('ip -o link show dev eth2 | grep 00:1a:4b:a6:a7:c4').and_return(false)
  end

  recipe do
    osl_fakenic 'eth1'

    osl_fakenic 'eth2' do
      ip4 '192.168.0.1/24'
      ip6 'fe80::1/64'
      mac_address '00:1a:4b:a6:a7:c4'
      multicast true
    end
  end

  it { is_expected.to install_kernel_module 'dummy' }

  # persist defaults to true, so a plain declaration is reboot-survivable.
  it { is_expected.to create_systemd_unit('osl-fakenic-eth1.service') }
  it { is_expected.to enable_service('osl-fakenic-eth1.service') }
  it { is_expected.to start_service('osl-fakenic-eth1.service') }
  it { is_expected.to run_execute('add fake interface eth1').with(command: 'ip link add name eth1 type dummy') }
  it { is_expected.to run_execute('bring fake eth1 online').with(command: 'ip link set dev eth1 up') }
  it { is_expected.to run_execute('add fake interface eth2').with(command: 'ip link add name eth2 type dummy') }
  it { is_expected.to run_execute('bring fake eth2 online').with(command: 'ip link set dev eth2 up') }
  it do
    is_expected.to run_execute('add IPv4 192.168.0.1/24 to eth2').with(
      command: 'ip addr add 192.168.0.1/24 dev eth2'
    )
  end
  it do
    is_expected.to run_execute('add IPv6 fe80::1/64 to eth2').with(
      command: 'ip -6 addr add fe80::1/64 dev eth2'
    )
  end
  it do
    is_expected.to run_execute('Set MAC address 00:1a:4b:a6:a7:c4 on eth2').with(
      command: 'ip link set dev eth2 address 00:1a:4b:a6:a7:c4'
    )
  end
  it { is_expected.to run_execute('enable multicast on eth2').with(command: 'ip link set eth2 multicast on') }

  context 'already exists' do
    cached(:subject) { chef_run }
    before do
      stub_command('ip a show dev eth1 | grep UP').and_return(true)
      stub_command('ip a show dev eth1').and_return(true)
      stub_command('ip a show dev eth2 | grep 192.168.0.1/24').and_return(true)
      stub_command('ip a show dev eth2 | grep UP').and_return(true)
      stub_command('ip a show dev eth2').and_return(true)
      stub_command('ip -6 a show dev eth2 | grep fe80::1/64').and_return(true)
      stub_command('ip a show dev eth2 | grep MULTICAST').and_return(true)
      stub_command('ip -o link show dev eth2 | grep 00:1a:4b:a6:a7:c4').and_return(true)
    end

    recipe do
      osl_fakenic 'eth1'
      osl_fakenic 'eth2' do
        ip4 '192.168.0.1/24'
        ip6 'fe80::1/64'
        mac_address '00:1a:4b:a6:a7:c4'
        multicast true
      end
    end

    it { is_expected.to_not run_execute('add fake interface eth1').with(command: 'ip link add name eth1 type dummy') }
    it { is_expected.to_not run_execute('bring fake eth1 online').with(command: 'ip link set dev eth1 up') }
    it { is_expected.to_not run_execute('add fake interface eth2').with(command: 'ip link add name eth2 type dummy') }
    it { is_expected.to_not run_execute('bring fake eth2 online').with(command: 'ip link set dev eth2 up') }
    it do
      is_expected.to_not run_execute('add IPv4 192.168.0.1/24 to eth2').with(
        command: 'ip addr add 192.168.0.1/24 dev eth2'
      )
    end
    it do
      is_expected.to_not run_execute('add IPv6 fe80::1/64 to eth2').with(
        command: 'ip -6 addr add fe80::1/64 dev eth2'
      )
    end
    it { is_expected.to_not run_execute('enable multicast on eth2').with(command: 'ip link set eth2 multicast on') }
  end

  context 'delete' do
    cached(:subject) { chef_run }

    before do
      stub_command(
        'ip link show dev eth1 && ' \
        'ip -details link show dev eth1 | tail -1 | grep dummy'
      ).and_return(true)
      stub_command(
        'ip link show dev eth1 | grep UP && ' \
        'ip -details link show dev eth1 | tail -1 | grep dummy'
      ).and_return(true)
      stub_command(
        'ip link show dev eth2 && ' \
        'ip -details link show dev eth2 | tail -1 | grep dummy'
      ).and_return(true)
      stub_command(
        'ip link show dev eth2 | grep UP && ' \
        'ip -details link show dev eth2 | tail -1 | grep dummy'
      ).and_return(false)
    end

    recipe do
      osl_fakenic 'eth1' do
        action :delete
      end
      osl_fakenic 'eth2' do
        action :delete
      end
    end

    it do
      is_expected.to run_execute('bring fake eth1 offline').with(
        command: 'ip link set dev eth1 down'
      )
    end
    it do
      is_expected.to run_execute('remove fake interface eth1').with(
        command: 'ip link delete eth1'
      )
    end
    it do
      is_expected.to_not run_execute('bring fake eth2 offline')
    end
    it do
      is_expected.to run_execute('remove fake interface eth2').with(
        command: 'ip link delete eth2'
      )
    end
  end
end

describe 'osl_fakenic persist' do
  platform 'almalinux'
  step_into :osl_fakenic

  before do
    # Pinned so the expected unit body does not depend on where `ip` happens
    # to live on whatever machine runs the specs.
    allow_any_instance_of(Chef::Provider).to receive(:osl_fakenic_ip_path).and_return('/usr/sbin/ip')
    allow(::File).to receive(:exist?).and_call_original
    %w(eth1 eth2).each do |i|
      stub_command("ip a show dev #{i}").and_return(false)
      stub_command("ip a show dev #{i} | grep UP").and_return(false)
      stub_command("ip a show dev #{i} | grep MULTICAST").and_return(false)
    end
    stub_command('ip a show dev eth2 | grep 192.168.0.1/24').and_return(false)
    stub_command('ip a show dev eth2 | grep 192.168.0.2/24').and_return(false)
    stub_command('ip -6 a show dev eth2 | grep fe80::1/64').and_return(false)
    stub_command('ip -o link show dev eth2 | grep 00:1a:4b:a6:a7:c4').and_return(false)
  end

  context 'a bare interface' do
    recipe { osl_fakenic 'eth1' }

    it do
      is_expected.to create_systemd_unit('osl-fakenic-eth1.service').with(
        content: <<~EOU
          [Unit]
          Description=Fake dummy interface eth1
          Wants=network-pre.target
          Before=network-pre.target NetworkManager.service

          [Service]
          Type=oneshot
          RemainAfterExit=yes
          ExecStart=-/usr/sbin/ip link add name eth1 type dummy
          ExecStart=/usr/sbin/ip link set dev eth1 up

          [Install]
          WantedBy=multi-user.target
        EOU
      )
    end

    it { is_expected.to enable_service('osl-fakenic-eth1.service') }
    it { is_expected.to start_service('osl-fakenic-eth1.service') }
  end

  # MAC and multicast are set before `up`, so the boot path never changes a
  # MAC on a live link, and addresses use `replace` so a rerun is not an error.
  context 'every property set' do
    recipe do
      osl_fakenic 'eth2' do
        ip4 %w(192.168.0.1/24 192.168.0.2/24)
        ip6 'fe80::1/64'
        mac_address '00:1a:4b:a6:a7:c4'
        multicast true
      end
    end

    it do
      is_expected.to create_systemd_unit('osl-fakenic-eth2.service').with(
        content: <<~EOU
          [Unit]
          Description=Fake dummy interface eth2
          Wants=network-pre.target
          Before=network-pre.target NetworkManager.service

          [Service]
          Type=oneshot
          RemainAfterExit=yes
          ExecStart=-/usr/sbin/ip link add name eth2 type dummy
          ExecStart=/usr/sbin/ip link set dev eth2 address 00:1a:4b:a6:a7:c4
          ExecStart=/usr/sbin/ip link set dev eth2 multicast on
          ExecStart=/usr/sbin/ip link set dev eth2 up
          ExecStart=/usr/sbin/ip addr replace 192.168.0.1/24 dev eth2
          ExecStart=/usr/sbin/ip addr replace 192.168.0.2/24 dev eth2
          ExecStart=/usr/sbin/ip -6 addr replace fe80::1/64 dev eth2

          [Install]
          WantedBy=multi-user.target
        EOU
      )
    end
  end

  context 'opting out with a unit already on disk' do
    before do
      allow(::File).to receive(:exist?)
        .with('/etc/systemd/system/osl-fakenic-eth1.service').and_return(true)
    end

    recipe do
      osl_fakenic 'eth1' do
        persist false
      end
    end

    it { is_expected.to stop_service('osl-fakenic-eth1.service') }
    it { is_expected.to disable_service('osl-fakenic-eth1.service') }
    it { is_expected.to delete_systemd_unit('osl-fakenic-eth1.service') }
  end

  # Opting out when the unit is already gone costs no systemctl round trips.
  context 'opting out with no unit on disk' do
    recipe do
      osl_fakenic 'eth1' do
        persist false
      end
    end

    it { is_expected.to_not stop_service('osl-fakenic-eth1.service') }
    it { is_expected.to_not delete_systemd_unit('osl-fakenic-eth1.service') }
  end

  context ':delete removes the unit' do
    before do
      allow(::File).to receive(:exist?)
        .with('/etc/systemd/system/osl-fakenic-eth1.service').and_return(true)
      stub_command('ip link show dev eth1 | grep UP && ip -details link show dev eth1 | tail -1 | grep dummy')
        .and_return(false)
      stub_command('ip link show dev eth1 && ip -details link show dev eth1 | tail -1 | grep dummy')
        .and_return(false)
    end

    recipe do
      osl_fakenic 'eth1' do
        action :delete
      end
    end

    it { is_expected.to delete_systemd_unit('osl-fakenic-eth1.service') }
  end

  # docker has no systemd to enable the unit into.
  context 'under docker' do
    automatic_attributes['virtualization'] = { 'systems' => { 'docker' => 'guest' } }

    recipe { osl_fakenic 'eth1' }

    it { is_expected.to_not create_systemd_unit('osl-fakenic-eth1.service') }
  end

  # systemd needs an absolute path and `ip` is not in the same place on every
  # platform, so the resolved path has to reach the unit.
  context 'with ip somewhere else' do
    before do
      allow_any_instance_of(Chef::Provider).to receive(:osl_fakenic_ip_path).and_return('/usr/bin/ip')
    end

    recipe { osl_fakenic 'eth1' }

    it do
      is_expected.to create_systemd_unit('osl-fakenic-eth1.service')
        .with_content(%r{^ExecStart=-/usr/bin/ip link add name eth1 type dummy$})
    end
  end
end
