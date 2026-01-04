require_relative '../../spec_helper'

describe 'osl_ipmi_user' do
  platform 'almalinux', '9'
  step_into :osl_ipmi_user

  # Stub password hash helper methods globally to avoid filesystem operations during unit tests
  before do
    allow(FileUtils).to receive(:mkdir_p).and_call_original
    allow(FileUtils).to receive(:mkdir_p).with('/var/lib/osl-ipmi', mode: 0o700).and_return(true)
    allow(File).to receive(:write).and_call_original
    allow(File).to receive(:write).with(%r{^/var/lib/osl-ipmi/}, anything).and_return(true)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(%r{^/var/lib/osl-ipmi/}).and_return('')
    allow(File).to receive(:delete).and_call_original
    allow(File).to receive(:delete).with(%r{^/var/lib/osl-ipmi/}).and_return(true)
    allow(File).to receive(:chmod).and_call_original
    allow(File).to receive(:chmod).with(0o600, %r{^/var/lib/osl-ipmi/}).and_return(true)
  end

  # Sample ipmitool user list output
  # Format: ID  Name  Callin  Link Auth  IPMI Msg  Channel Priv Limit
  let(:user_list_output) do
    <<~OUTPUT
      ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
      1                    true    false      true       USER
      2                    true    false      false      Unknown (0x00)
      3                    true    false      false      Unknown (0x00)
      4                    true    false      false      Unknown (0x00)
      5                    true    false      false      Unknown (0x00)
    OUTPUT
  end

  let(:user_list_with_admin) do
    <<~OUTPUT
      ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
      1                    true    false      true       USER
      2                    true    false      false      Unknown (0x00)
      3   admin            true    false      true       ADMINISTRATOR
      4                    true    false      false      Unknown (0x00)
      5                    true    false      false      Unknown (0x00)
    OUTPUT
  end

  let(:user_list_with_operator) do
    <<~OUTPUT
      ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
      1                    true    false      true       USER
      2                    true    false      false      Unknown (0x00)
      3   admin            true    false      true       OPERATOR
      4                    true    false      false      Unknown (0x00)
      5                    true    false      false      Unknown (0x00)
    OUTPUT
  end

  let(:user_list_with_disabled) do
    <<~OUTPUT
      ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
      1                    true    false      true       USER
      2                    true    false      false      Unknown (0x00)
      3   admin            true    false      false      ADMINISTRATOR
      4                    true    false      false      Unknown (0x00)
      5                    true    false      false      Unknown (0x00)
    OUTPUT
  end

  context 'create action - new user' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        password 'testpassword123'
        privilege :administrator
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to create_osl_ipmi_user('admin') }
  end

  context 'create action - user exists with correct privilege' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_with_admin)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        password 'testpassword123'
        privilege :administrator
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to create_osl_ipmi_user('admin') }
  end

  context 'create action - user exists with different privilege' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_with_operator)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        password 'testpassword123'
        privilege :administrator
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to create_osl_ipmi_user('admin') }
  end

  context 'create action - user exists but disabled' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_with_disabled)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        password 'testpassword123'
        privilege :administrator
        enabled true
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to create_osl_ipmi_user('admin') }
  end

  context 'create action with integer privilege' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'operator' do
        password 'testpassword123'
        privilege 3
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to create_osl_ipmi_user('operator') }
  end

  context 'create action with custom channel' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        password 'testpassword123'
        privilege :administrator
        channel 2
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to create_osl_ipmi_user('admin') }
  end

  context 'delete action - user exists' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_with_admin)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        action :delete
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to delete_osl_ipmi_user('admin') }
  end

  context 'delete action - user does not exist' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'nonexistent' do
        action :delete
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to delete_osl_ipmi_user('nonexistent') }
  end

  context 'modify action - user exists' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_with_admin)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        password 'newpassword123'
        privilege :administrator
        action :modify
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to modify_osl_ipmi_user('admin') }
  end

  context 'modify action - user does not exist' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'nonexistent' do
        password 'newpassword123'
        privilege :administrator
        action :modify
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to modify_osl_ipmi_user('nonexistent') }
  end

  context 'no IPMI device available' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
    end

    recipe do
      osl_ipmi_user 'admin' do
        password 'testpassword123'
        privilege :administrator
      end
    end

    it { is_expected.to_not install_package('ipmitool') }
    it { is_expected.to create_osl_ipmi_user('admin') }
  end

  context 'username validation' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'exactly16chars!!' do
        password 'testpassword123'
        privilege :administrator
      end
    end

    it 'allows username with exactly 16 characters' do
      is_expected.to create_osl_ipmi_user('exactly16chars!!')
    end
  end

  context 'password validation - max 20 characters' do
    cached(:subject) { chef_run }

    let(:mc_info_output) do
      <<~OUTPUT
        Device ID                 : 32
        IPMI Version              : 2.0
      OUTPUT
    end

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      # Mock shell commands - return appropriate output based on command
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout) do |shellout|
        if shellout.command.include?('mc info')
          mc_info_output
        else
          user_list_output
        end
      end
    end

    recipe do
      osl_ipmi_user 'admin' do
        password '12345678901234567890' # exactly 20 characters
        privilege :administrator
      end
    end

    it 'allows password with exactly 20 characters on IPMI 2.0' do
      is_expected.to create_osl_ipmi_user('admin')
    end
  end

  context 'password validation - IPMI 1.5 rejects 17+ chars' do
    let(:mc_info_output) do
      <<~OUTPUT
        Device ID                 : 32
        IPMI Version              : 1.5
      OUTPUT
    end

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout) do |shellout|
        if shellout.command.include?('mc info')
          mc_info_output
        else
          user_list_output
        end
      end
    end

    recipe do
      osl_ipmi_user 'admin' do
        password '12345678901234567' # 17 characters - over the 16 limit
        privilege :administrator
      end
    end

    it 'raises an error for password over 16 characters on IPMI 1.5' do
      expect { chef_run }.to raise_error(RuntimeError, /Password exceeds maximum length of 16 characters for IPMI 1.5/)
    end
  end

  context 'all privilege symbols - callback' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'user_callback' do
        password 'testpassword123'
        privilege :callback
      end
    end

    it { is_expected.to create_osl_ipmi_user('user_callback') }
  end

  context 'all privilege symbols - user' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'user_user' do
        password 'testpassword123'
        privilege :user
      end
    end

    it { is_expected.to create_osl_ipmi_user('user_user') }
  end

  context 'all privilege symbols - operator' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'user_operator' do
        password 'testpassword123'
        privilege :operator
      end
    end

    it { is_expected.to create_osl_ipmi_user('user_operator') }
  end

  context 'all privilege symbols - administrator' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'user_admin' do
        password 'testpassword123'
        privilege :administrator
      end
    end

    it { is_expected.to create_osl_ipmi_user('user_admin') }
  end

  context 'all privilege symbols - oem' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'user_oem' do
        password 'testpassword123'
        privilege :oem
      end
    end

    it { is_expected.to create_osl_ipmi_user('user_oem') }
  end

  context 'create disabled user' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'disabled_user' do
        password 'testpassword123'
        privilege :user
        enabled false
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to create_osl_ipmi_user('disabled_user') }
  end

  # Edge case: Delete user in protected slot (should warn and skip)
  context 'delete action - user in protected slot' do
    let(:user_list_protected_slot) do
      <<~OUTPUT
        ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
        1                    true    false      true       USER
        2   protecteduser    true    false      true       ADMINISTRATOR
        3                    true    false      false      Unknown (0x00)
      OUTPUT
    end

    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_protected_slot)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'protecteduser' do
        action :delete
      end
    end

    it 'should not delete user in protected slot (slot 2 < min_slot 3)' do
      expect(Chef::Log).to receive(:warn).with(/Cannot delete user in protected slot 2/)
      chef_run
    end
  end

  # Edge case: No available slots
  context 'create action - no available slots' do
    let(:user_list_full) do
      <<~OUTPUT
        ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
        1   root             true    false      true       USER
        2   admin            true    false      true       ADMINISTRATOR
        3   user1            true    false      true       USER
        4   user2            true    false      true       USER
        5   user3            true    false      true       USER
        6   user4            true    false      true       USER
        7   user5            true    false      true       USER
        8   user6            true    false      true       USER
        9   user7            true    false      true       USER
        10  user8            true    false      true       USER
        11  user9            true    false      true       USER
        12  user10           true    false      true       USER
        13  user11           true    false      true       USER
        14  user12           true    false      true       USER
        15  user13           true    false      true       USER
      OUTPUT
    end

    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_full)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'newuser' do
        password 'testpassword123'
        privilege :user
      end
    end

    it 'should warn when no available slots' do
      expect(Chef::Log).to receive(:warn).with(/No available IPMI user slots/)
      chef_run
    end
  end

  # Edge case: Alternative IPMI device path (/dev/ipmi/0)
  context 'alternative IPMI device - /dev/ipmi/0' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        password 'testpassword123'
        privilege :administrator
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to create_osl_ipmi_user('admin') }
  end

  # Edge case: Alternative IPMI device path (/dev/ipmidev/0)
  context 'alternative IPMI device - /dev/ipmidev/0' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(true)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        password 'testpassword123'
        privilege :administrator
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to create_osl_ipmi_user('admin') }
  end

  # Edge case: Custom min_slot value
  context 'create action with custom min_slot' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_output)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        password 'testpassword123'
        privilege :administrator
        min_slot 5
      end
    end

    it { is_expected.to install_package('ipmitool') }
    it { is_expected.to create_osl_ipmi_user('admin') }
  end

  # Edge case: Modify user changing only enabled status
  context 'modify action - change only enabled status' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_with_admin)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        enabled false
        action :modify
      end
    end

    it { is_expected.to modify_osl_ipmi_user('admin') }
  end

  # Edge case: Modify user with privilege change
  context 'modify action - change privilege from ADMIN to OPERATOR' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_with_admin)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'admin' do
        privilege :operator
        action :modify
      end
    end

    it { is_expected.to modify_osl_ipmi_user('admin') }
  end

  # Edge case: Delete action with custom min_slot
  context 'delete action - respect custom min_slot' do
    let(:user_list_slot4) do
      <<~OUTPUT
        ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
        1                    true    false      true       USER
        2                    true    false      false      Unknown (0x00)
        3                    true    false      false      Unknown (0x00)
        4   testuser         true    false      true       ADMINISTRATOR
      OUTPUT
    end

    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_slot4)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'testuser' do
        min_slot 5
        action :delete
      end
    end

    it 'should not delete user below custom min_slot' do
      expect(Chef::Log).to receive(:warn).with(/Cannot delete user in protected slot 4/)
      chef_run
    end
  end

  # Edge case: Delete action skips with no IPMI device
  context 'delete action - no IPMI device' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
    end

    recipe do
      osl_ipmi_user 'admin' do
        action :delete
      end
    end

    it { is_expected.to_not install_package('ipmitool') }
    it { is_expected.to delete_osl_ipmi_user('admin') }
  end

  # Edge case: Modify action skips with no IPMI device
  context 'modify action - no IPMI device' do
    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
    end

    recipe do
      osl_ipmi_user 'admin' do
        privilege :administrator
        action :modify
      end
    end

    it { is_expected.to_not install_package('ipmitool') }
    it { is_expected.to modify_osl_ipmi_user('admin') }
  end

  # Edge case: User with NO ACCESS privilege
  context 'parsing user with NO ACCESS privilege' do
    let(:user_list_no_access) do
      <<~OUTPUT
        ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
        1                    true    false      true       USER
        2                    true    false      false      NO ACCESS
        3   noaccessuser     true    false      false      NO ACCESS
      OUTPUT
    end

    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_no_access)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'newadmin' do
        password 'testpassword123'
        privilege :administrator
      end
    end

    it { is_expected.to create_osl_ipmi_user('newadmin') }
  end

  # Edge case: User with OEM PROPRIETARY privilege
  context 'parsing user with OEM PROPRIETARY privilege' do
    let(:user_list_oem) do
      <<~OUTPUT
        ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
        1                    true    false      true       USER
        2                    true    false      false      Unknown (0x00)
        3   oemuser          true    false      true       OEM PROPRIETARY
      OUTPUT
    end

    cached(:subject) { chef_run }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:error!).and_return(nil)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return(user_list_oem)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stderr).and_return('')
      allow_any_instance_of(Mixlib::ShellOut).to receive(:exitstatus).and_return(0)
    end

    recipe do
      osl_ipmi_user 'oemuser' do
        password 'testpassword123'
        privilege :oem
      end
    end

    # Should not update as user already has OEM privilege
    it { is_expected.to create_osl_ipmi_user('oemuser') }
  end
end
