require_relative '../../spec_helper'
require_relative '../../../libraries/helpers'

RSpec.describe OSLResources::Cookbook::Helpers do
  class DummyClass < Chef::Node
    include OSLResources::Cookbook::Helpers
  end

  # Use a simple object for testing IPMI methods to avoid Chef::Node method_missing
  class SimpleTestClass
    include OSLResources::Cookbook::Helpers
  end

  subject { DummyClass.new }
  let(:simple_subject) { SimpleTestClass.new }

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

  describe '#ipmi_privilege_string_to_int' do
    it 'converts CALLBACK' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, 'CALLBACK')).to eq 1
    end
    it 'converts USER' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, 'USER')).to eq 2
    end
    it 'converts OPERATOR' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, 'OPERATOR')).to eq 3
    end
    it 'converts ADMINISTRATOR' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, 'ADMINISTRATOR')).to eq 4
    end
    it 'converts ADMIN' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, 'ADMIN')).to eq 4
    end
    it 'converts OEM PROPRIETARY' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, 'OEM PROPRIETARY')).to eq 5
    end
    it 'converts OEM' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, 'OEM')).to eq 5
    end
    it 'converts NO ACCESS' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, 'NO ACCESS')).to eq 0
    end
    it 'converts UNKNOWN' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, 'UNKNOWN')).to eq 0
    end
    it 'handles lowercase' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, 'administrator')).to eq 4
    end
    it 'handles whitespace' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, '  OPERATOR  ')).to eq 3
    end
    it 'returns 0 for unknown strings' do
      expect(simple_subject.send(:ipmi_privilege_string_to_int, 'INVALID')).to eq 0
    end
  end

  describe '#ipmi_privilege_to_int' do
    it 'converts :callback symbol' do
      expect(simple_subject.send(:ipmi_privilege_to_int, :callback)).to eq 1
    end
    it 'converts :user symbol' do
      expect(simple_subject.send(:ipmi_privilege_to_int, :user)).to eq 2
    end
    it 'converts :operator symbol' do
      expect(simple_subject.send(:ipmi_privilege_to_int, :operator)).to eq 3
    end
    it 'converts :administrator symbol' do
      expect(simple_subject.send(:ipmi_privilege_to_int, :administrator)).to eq 4
    end
    it 'converts :oem symbol' do
      expect(simple_subject.send(:ipmi_privilege_to_int, :oem)).to eq 5
    end
    it 'passes through integers' do
      expect(simple_subject.send(:ipmi_privilege_to_int, 3)).to eq 3
    end
    it 'raises error for invalid privilege' do
      expect { simple_subject.send(:ipmi_privilege_to_int, :invalid) }.to raise_error(ArgumentError)
    end
  end

  describe '#ipmi_parse_user_list' do
    let(:standard_output) do
      <<~OUTPUT
        ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
        1                    true    false      true       USER
        2                    true    false      false      Unknown (0x00)
        3   admin            true    false      true       ADMINISTRATOR
        4   operator         true    false      true       OPERATOR
        5   disabled         true    false      false      USER
      OUTPUT
    end

    it 'parses user list correctly' do
      users = simple_subject.send(:ipmi_parse_user_list, standard_output)
      expect(users.length).to eq 5
    end

    it 'correctly parses empty username in slot 1' do
      users = simple_subject.send(:ipmi_parse_user_list, standard_output)
      user1 = users.find { |u| u[:slot] == 1 }
      expect(user1[:username]).to eq ''
      expect(user1[:enabled]).to eq true
      expect(user1[:privilege]).to eq 2 # USER
    end

    it 'correctly parses admin user' do
      users = simple_subject.send(:ipmi_parse_user_list, standard_output)
      admin = users.find { |u| u[:username] == 'admin' }
      expect(admin[:slot]).to eq 3
      expect(admin[:enabled]).to eq true
      expect(admin[:privilege]).to eq 4 # ADMINISTRATOR
    end

    it 'correctly parses disabled user' do
      users = simple_subject.send(:ipmi_parse_user_list, standard_output)
      disabled = users.find { |u| u[:username] == 'disabled' }
      expect(disabled[:slot]).to eq 5
      expect(disabled[:enabled]).to eq false
      expect(disabled[:privilege]).to eq 2 # USER
    end

    it 'handles empty output' do
      users = simple_subject.send(:ipmi_parse_user_list, '')
      expect(users).to eq []
    end

    it 'handles output with only header' do
      header_only = "ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit\n"
      users = simple_subject.send(:ipmi_parse_user_list, header_only)
      expect(users).to eq []
    end

    it 'handles NO ACCESS privilege' do
      output = <<~OUTPUT
        ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
        1                    true    false      false      NO ACCESS
      OUTPUT
      users = simple_subject.send(:ipmi_parse_user_list, output)
      expect(users.first[:privilege]).to eq 0
    end

    it 'handles OEM PROPRIETARY privilege' do
      output = <<~OUTPUT
        ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
        3   oemuser          true    false      true       OEM PROPRIETARY
      OUTPUT
      users = simple_subject.send(:ipmi_parse_user_list, output)
      expect(users.first[:privilege]).to eq 5
    end
  end

  describe '#ipmi_available?' do
    it 'returns true when /dev/ipmi0 exists' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      expect(simple_subject.send(:ipmi_available?)).to eq true
    end

    it 'returns true when /dev/ipmi/0 exists' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(true)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      expect(simple_subject.send(:ipmi_available?)).to eq true
    end

    it 'returns true when /dev/ipmidev/0 exists' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(true)
      expect(simple_subject.send(:ipmi_available?)).to eq true
    end

    it 'returns false when no IPMI device exists' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with('/dev/ipmi0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmi/0').and_return(false)
      allow(File).to receive(:exist?).with('/dev/ipmidev/0').and_return(false)
      expect(simple_subject.send(:ipmi_available?)).to eq false
    end
  end

  describe '#ipmi_version' do
    it 'returns 2.0 for IPMI 2.0 hardware' do
      allow(simple_subject).to receive(:run_ipmi_command).with('mc info').and_return("IPMI Version              : 2.0\n")
      expect(simple_subject.send(:ipmi_version)).to eq 2.0
    end

    it 'returns 1.5 for IPMI 1.5 hardware' do
      allow(simple_subject).to receive(:run_ipmi_command).with('mc info').and_return("IPMI Version              : 1.5\n")
      expect(simple_subject.send(:ipmi_version)).to eq 1.5
    end

    it 'returns 1.5 when version cannot be detected' do
      allow(simple_subject).to receive(:run_ipmi_command).with('mc info').and_return("Unknown output\n")
      expect(simple_subject.send(:ipmi_version)).to eq 1.5
    end

    it 'returns 1.5 on command failure' do
      allow(simple_subject).to receive(:run_ipmi_command).with('mc info').and_raise(Mixlib::ShellOut::ShellCommandFailed)
      expect(simple_subject.send(:ipmi_version)).to eq 1.5
    end
  end

  describe '#ipmi_supports_20_byte_password?' do
    it 'returns true for IPMI 2.0' do
      allow(simple_subject).to receive(:ipmi_version).and_return(2.0)
      expect(simple_subject.send(:ipmi_supports_20_byte_password?)).to eq true
    end

    it 'returns false for IPMI 1.5' do
      allow(simple_subject).to receive(:ipmi_version).and_return(1.5)
      expect(simple_subject.send(:ipmi_supports_20_byte_password?)).to eq false
    end
  end

  describe '#ipmi_max_password_length' do
    it 'returns 20 for IPMI 2.0' do
      allow(simple_subject).to receive(:ipmi_supports_20_byte_password?).and_return(true)
      expect(simple_subject.send(:ipmi_max_password_length)).to eq 20
    end

    it 'returns 16 for IPMI 1.5' do
      allow(simple_subject).to receive(:ipmi_supports_20_byte_password?).and_return(false)
      expect(simple_subject.send(:ipmi_max_password_length)).to eq 16
    end
  end

  describe '#ipmi_set_privilege' do
    it 'sets privilege with channel access enabled' do
      expect(simple_subject).to receive(:run_ipmi_command)
        .with('channel setaccess 1 3 privilege=4 ipmi=on link=on')
      simple_subject.send(:ipmi_set_privilege, 3, 4, 1)
    end

    it 'uses the specified channel' do
      expect(simple_subject).to receive(:run_ipmi_command)
        .with('channel setaccess 2 5 privilege=3 ipmi=on link=on')
      simple_subject.send(:ipmi_set_privilege, 5, 3, 2)
    end
  end

  describe '#ipmi_enable_user' do
    it 'enables user globally and sets channel access' do
      expect(simple_subject).to receive(:run_ipmi_command).with('user enable 3').ordered
      expect(simple_subject).to receive(:run_ipmi_command)
        .with('channel setaccess 1 3 ipmi=on link=on').ordered
      simple_subject.send(:ipmi_enable_user, 3, 1)
    end

    it 'uses default channel 1 when not specified' do
      expect(simple_subject).to receive(:run_ipmi_command).with('user enable 4').ordered
      expect(simple_subject).to receive(:run_ipmi_command)
        .with('channel setaccess 1 4 ipmi=on link=on').ordered
      simple_subject.send(:ipmi_enable_user, 4)
    end

    it 'uses the specified channel' do
      expect(simple_subject).to receive(:run_ipmi_command).with('user enable 5').ordered
      expect(simple_subject).to receive(:run_ipmi_command)
        .with('channel setaccess 2 5 ipmi=on link=on').ordered
      simple_subject.send(:ipmi_enable_user, 5, 2)
    end
  end

  describe '#ipmi_disable_user' do
    it 'disables channel access first, then disables user globally' do
      expect(simple_subject).to receive(:run_ipmi_command)
        .with('channel setaccess 1 3 ipmi=off link=off').ordered
      expect(simple_subject).to receive(:run_ipmi_command).with('user disable 3').ordered
      simple_subject.send(:ipmi_disable_user, 3, 1)
    end

    it 'uses default channel 1 when not specified' do
      expect(simple_subject).to receive(:run_ipmi_command)
        .with('channel setaccess 1 4 ipmi=off link=off').ordered
      expect(simple_subject).to receive(:run_ipmi_command).with('user disable 4').ordered
      simple_subject.send(:ipmi_disable_user, 4)
    end

    it 'uses the specified channel' do
      expect(simple_subject).to receive(:run_ipmi_command)
        .with('channel setaccess 3 5 ipmi=off link=off').ordered
      expect(simple_subject).to receive(:run_ipmi_command).with('user disable 5').ordered
      simple_subject.send(:ipmi_disable_user, 5, 3)
    end
  end

  describe '#ipmi_set_enabled' do
    it 'calls ipmi_enable_user when enabled is true' do
      expect(simple_subject).to receive(:ipmi_enable_user).with(3, 1)
      simple_subject.send(:ipmi_set_enabled, 3, true, 1)
    end

    it 'calls ipmi_disable_user when enabled is false' do
      expect(simple_subject).to receive(:ipmi_disable_user).with(3, 1)
      simple_subject.send(:ipmi_set_enabled, 3, false, 1)
    end

    it 'passes channel to enable_user' do
      expect(simple_subject).to receive(:ipmi_enable_user).with(5, 2)
      simple_subject.send(:ipmi_set_enabled, 5, true, 2)
    end

    it 'passes channel to disable_user' do
      expect(simple_subject).to receive(:ipmi_disable_user).with(5, 2)
      simple_subject.send(:ipmi_set_enabled, 5, false, 2)
    end

    it 'uses default channel 1 when not specified' do
      expect(simple_subject).to receive(:ipmi_enable_user).with(3, 1)
      simple_subject.send(:ipmi_set_enabled, 3, true)
    end
  end

  describe '#ipmi_set_username' do
    it 'sets username for slot' do
      expect(simple_subject).to receive(:run_ipmi_command).with('user set name 3 admin')
      simple_subject.send(:ipmi_set_username, 3, 'admin')
    end
  end

  describe '#ipmi_set_password' do
    it 'sets password for slot with standard length' do
      expect(simple_subject).to receive(:run_ipmi_command).with('user set password 3 secret123')
      simple_subject.send(:ipmi_set_password, 3, 'secret123')
    end

    it 'sets password with 20-byte mode for passwords over 16 chars' do
      long_password = '12345678901234567' # 17 chars
      expect(simple_subject).to receive(:run_ipmi_command)
        .with("user set password 3 #{long_password} 20")
      simple_subject.send(:ipmi_set_password, 3, long_password)
    end

    it 'uses standard mode for exactly 16 char password' do
      password_16 = '1234567890123456' # exactly 16 chars
      expect(simple_subject).to receive(:run_ipmi_command)
        .with("user set password 3 #{password_16}")
      simple_subject.send(:ipmi_set_password, 3, password_16)
    end
  end

  describe '#ipmi_password_hash' do
    it 'generates a SHA256 hash of username and password' do
      hash = simple_subject.send(:ipmi_password_hash, 'admin', 'secret123')
      expect(hash).to match(/^[a-f0-9]{64}$/)
    end

    it 'returns different hashes for different passwords' do
      hash1 = simple_subject.send(:ipmi_password_hash, 'admin', 'password1')
      hash2 = simple_subject.send(:ipmi_password_hash, 'admin', 'password2')
      expect(hash1).not_to eq(hash2)
    end

    it 'returns different hashes for different usernames' do
      hash1 = simple_subject.send(:ipmi_password_hash, 'user1', 'password')
      hash2 = simple_subject.send(:ipmi_password_hash, 'user2', 'password')
      expect(hash1).not_to eq(hash2)
    end

    it 'returns consistent hashes for same input' do
      hash1 = simple_subject.send(:ipmi_password_hash, 'admin', 'secret')
      hash2 = simple_subject.send(:ipmi_password_hash, 'admin', 'secret')
      expect(hash1).to eq(hash2)
    end
  end

  describe '#ipmi_password_needs_update?' do
    let(:hash_file) { '/var/lib/osl-ipmi/testuser.pwdhash' }

    it 'returns true when hash file does not exist' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(hash_file).and_return(false)
      expect(simple_subject.send(:ipmi_password_needs_update?, 'testuser', 'password')).to eq true
    end

    it 'returns false when password hash matches' do
      expected_hash = simple_subject.send(:ipmi_password_hash, 'testuser', 'password')
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(hash_file).and_return(true)
      allow(File).to receive(:read).with(hash_file).and_return(expected_hash)
      expect(simple_subject.send(:ipmi_password_needs_update?, 'testuser', 'password')).to eq false
    end

    it 'returns true when password hash does not match' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(hash_file).and_return(true)
      allow(File).to receive(:read).with(hash_file).and_return('oldhash123')
      expect(simple_subject.send(:ipmi_password_needs_update?, 'testuser', 'newpassword')).to eq true
    end

    it 'handles hash file with trailing whitespace' do
      expected_hash = simple_subject.send(:ipmi_password_hash, 'testuser', 'password')
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(hash_file).and_return(true)
      allow(File).to receive(:read).with(hash_file).and_return("#{expected_hash}\n")
      expect(simple_subject.send(:ipmi_password_needs_update?, 'testuser', 'password')).to eq false
    end
  end

  describe '#ipmi_save_password_hash' do
    let(:hash_file) { '/var/lib/osl-ipmi/testuser.pwdhash' }
    let(:state_dir) { '/var/lib/osl-ipmi' }

    it 'creates state directory and writes hash file' do
      expect(FileUtils).to receive(:mkdir_p).with(state_dir, mode: 0700)
      expect(File).to receive(:write).with(hash_file, anything)
      expect(File).to receive(:chmod).with(0600, hash_file)
      simple_subject.send(:ipmi_save_password_hash, 'testuser', 'password')
    end
  end

  describe '#ipmi_remove_password_hash' do
    let(:hash_file) { '/var/lib/osl-ipmi/testuser.pwdhash' }

    it 'removes hash file when it exists' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(hash_file).and_return(true)
      expect(File).to receive(:delete).with(hash_file)
      simple_subject.send(:ipmi_remove_password_hash, 'testuser')
    end

    it 'does nothing when hash file does not exist' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(hash_file).and_return(false)
      expect(File).not_to receive(:delete)
      simple_subject.send(:ipmi_remove_password_hash, 'testuser')
    end
  end
end
