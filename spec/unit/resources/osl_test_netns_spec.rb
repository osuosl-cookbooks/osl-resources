require_relative '../../spec_helper'

describe 'osl_test_netns' do
  platform 'almalinux'
  step_into :osl_test_netns

  context 'fresh create' do
    cached(:subject) { chef_run }

    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_exists?).and_return(false)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_exists?).and_return(false)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(false)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_has_addr?).and_return(false)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_has_mac?).and_return(false)
    end

    recipe do
      osl_test_netns 'testclient' do
        server_interface 'veth-srv'
        server_ip '140.211.166.158/28'
        client_interface 'veth-cli'
        client_ip '140.211.166.157/28'
        client_mac '00:1a:4b:a6:a7:c4'
      end
    end

    it { is_expected.to run_execute('create netns testclient').with(command: 'ip netns add testclient') }
    it do
      is_expected.to run_execute('create veth pair veth-srv <-> veth-cli').with(
        command: 'ip link add veth-srv type veth peer name veth-cli'
      )
    end
    it do
      is_expected.to run_execute('move veth-cli to netns testclient').with(
        command: 'ip link set veth-cli netns testclient'
      )
    end
    it do
      is_expected.to run_execute('assign IP 140.211.166.158/28 to veth-srv').with(
        command: 'ip addr add 140.211.166.158/28 dev veth-srv'
      )
    end
    it { is_expected.to run_execute('bring veth-srv up').with(command: 'ip link set veth-srv up') }
    it do
      is_expected.to run_execute('set MAC 00:1a:4b:a6:a7:c4 on veth-cli in netns testclient').with(
        command: 'ip -n testclient link set veth-cli address 00:1a:4b:a6:a7:c4'
      )
    end
    it do
      is_expected.to run_execute('assign IP 140.211.166.157/28 to veth-cli in netns testclient').with(
        command: 'ip -n testclient addr add 140.211.166.157/28 dev veth-cli'
      )
    end
    it do
      is_expected.to run_execute('bring veth-cli up in netns testclient').with(
        command: 'ip -n testclient link set veth-cli up'
      )
    end
    it do
      is_expected.to run_execute('bring lo up in netns testclient').with(
        command: 'ip -n testclient link set lo up'
      )
    end
  end

  context 'already exists' do
    cached(:subject) { chef_run }

    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_exists?).and_return(true)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_exists?).and_return(true)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_admin_up?).and_return(true)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_has_addr?).and_return(true)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_has_mac?).and_return(true)
    end

    recipe do
      osl_test_netns 'testclient' do
        server_interface 'veth-srv'
        server_ip '140.211.166.158/28'
        client_interface 'veth-cli'
        client_ip '140.211.166.157/28'
        client_mac '00:1a:4b:a6:a7:c4'
      end
    end

    it { is_expected.to_not run_execute('create netns testclient') }
    it { is_expected.to_not run_execute('create veth pair veth-srv <-> veth-cli') }
    it { is_expected.to_not run_execute('move veth-cli to netns testclient') }
    it { is_expected.to_not run_execute('assign IP 140.211.166.158/28 to veth-srv') }
    it { is_expected.to_not run_execute('bring veth-srv up') }
    it { is_expected.to_not run_execute('set MAC 00:1a:4b:a6:a7:c4 on veth-cli in netns testclient') }
    it { is_expected.to_not run_execute('assign IP 140.211.166.157/28 to veth-cli in netns testclient') }
    it { is_expected.to_not run_execute('bring veth-cli up in netns testclient') }
    it { is_expected.to_not run_execute('bring lo up in netns testclient') }
  end

  context 'delete with everything still present' do
    cached(:subject) { chef_run }

    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_exists?).and_return(true)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_exists?).and_return(true)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_is_type?).and_return(true)
    end

    recipe do
      osl_test_netns 'testclient' do
        server_interface 'veth-srv'
        server_ip '140.211.166.158/28'
        client_interface 'veth-cli'
        client_ip '140.211.166.157/28'
        action :delete
      end
    end

    it do
      is_expected.to run_execute('bring veth-cli down in netns testclient').with(
        command: 'ip -n testclient link set veth-cli down'
      )
    end
    it do
      is_expected.to run_execute('move veth-cli back to host netns').with(
        command: 'ip -n testclient link set veth-cli netns 1'
      )
    end
    it do
      is_expected.to run_execute('delete veth veth-srv').with(
        command: 'ip link delete veth-srv'
      )
    end
    it do
      is_expected.to run_execute('delete netns testclient').with(
        command: 'ip netns delete testclient'
      )
    end
  end

  context 'delete when state is partially gone' do
    cached(:subject) { chef_run }

    before do
      # Netns is still around, but the veth pair is already torn down.
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_exists?).and_return(true)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_exists?).and_return(false)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_is_type?).and_return(false)
    end

    recipe do
      osl_test_netns 'partial' do
        server_ip '192.0.2.1/30'
        client_ip '192.0.2.2/30'
        action :delete
      end
    end

    it { is_expected.to_not run_execute('bring veth-cli-partia down in netns partial') }
    it { is_expected.to_not run_execute('move veth-cli-partia back to host netns') }
    it { is_expected.to_not run_execute('delete veth veth-srv-partia') }
    it do
      is_expected.to run_execute('delete netns partial').with(
        command: 'ip netns delete partial'
      )
    end
  end

  context 'delete when nothing remains' do
    cached(:subject) { chef_run }

    before do
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_exists?).and_return(false)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_exists?).and_return(false)
      allow_any_instance_of(Chef::Resource).to receive(:osl_netns_link_is_type?).and_return(false)
    end

    recipe do
      osl_test_netns 'gone' do
        server_ip '192.0.2.1/30'
        client_ip '192.0.2.2/30'
        action :delete
      end
    end

    it { is_expected.to_not run_execute('bring veth-cli-gone down in netns gone') }
    it { is_expected.to_not run_execute('move veth-cli-gone back to host netns') }
    it { is_expected.to_not run_execute('delete veth veth-srv-gone') }
    it { is_expected.to_not run_execute('delete netns gone') }
  end
end
