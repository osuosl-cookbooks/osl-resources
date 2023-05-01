require_relative '../../spec_helper'

describe 'osl_fakenic' do
  platform 'almalinux'
  cached(:subject) { chef_run }
  step_into :osl_fakenic

  before do
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
