require_relative '../../spec_helper'

describe 'osl_authorized_keys' do
  platform 'almalinux'
  step_into :osl_authorized_keys

  before do
    allow(Dir).to receive(:empty?).with('/home/test_user_1/.ssh').and_return(true)
    allow(Dir).to receive(:empty?).with('/home/test_user_3/.ssh').and_return(false)
    allow(File).to receive(:empty?).with('/home/test_user_1/.ssh/authorized_keys').and_return(true)
    allow(File).to receive(:empty?).with('/home/test_user_3/.ssh/authorized_keys').and_return(false)
  end

  keys =
    [
      {
        'name' => 'key_1',
        'sum' => '6866ef97',
      },
      {
        'name' => 'key_2',
        'sum' => '1388ac75',
      },
      {
        'name' => 'key_3',
        'sum' => '07ef8d13',
      },
    ]

  recipe do
    %w(key_1 key_2 key_3).each do |k|
      osl_authorized_keys k do
        user 'test_user_1'
        exclusive false
        action [:add, :remove]
      end
    end

    osl_authorized_keys 'test_user_2' do
      key %w(key_1 key_2 key_3)
      user 'test_user_2'
      group 'nobody'
      dir_path '/opt/test/.ssh'
      exclusive false
    end

    osl_authorized_keys 'key_2' do
      user 'test_user_3'
      action :remove
    end

    osl_authorized_keys 'ssh-ed25519 AAAA+plus test@example.org' do
      user 'test_user_3'
      action :remove
    end

    osl_authorized_keys 'test_user_4' do
      key %w(key_1 key_2 key_1)
      user 'test_user_4'
    end

    osl_authorized_keys 'key_3' do
      user 'test_user_4'
      exclusive true
    end
  end

  it do
    is_expected.to create_directory('/home/test_user_4/.ssh').with(
      mode: '0700',
      owner: 'test_user_4',
      group: 'test_user_4'
    )
  end

  it do
    is_expected.to create_file('osl_authorized_keys /home/test_user_4/.ssh/authorized_keys').with(
      path: '/home/test_user_4/.ssh/authorized_keys',
      content: "key_1\nkey_2\nkey_3\n",
      owner: 'test_user_4',
      group: 'test_user_4',
      mode: '0600'
    )
  end

  keys.each do |k|
    it { is_expected.to_not edit_line_append_if_no_line("test_user_4-#{k['sum']}") }
  end

  it do
    is_expected.to create_directory('/home/test_user_1/.ssh').with(
      mode: '0700',
      owner: 'test_user_1',
      group: 'test_user_1'
    )
  end

  keys.each do |k|
    it do
      is_expected.to edit_line_append_if_no_line("test_user_1-#{k['sum']}").with(
        path: '/home/test_user_1/.ssh/authorized_keys',
        line: k['name'],
        owner: 'test_user_1',
        group: 'test_user_1'
      )
    end
  end

  keys.each do |k|
    it do
      is_expected.to edit_line_delete_lines("test_user_1-#{k['sum']}").with(
        path: '/home/test_user_1/.ssh/authorized_keys',
        pattern: eq(/^#{Regexp.escape(k['name'])}$/)
      )
    end
  end

  it do
    is_expected.to delete_directory('/home/test_user_1/.ssh')
  end

  it do
    is_expected.to delete_file('/home/test_user_1/.ssh/authorized_keys')
  end

  it do
    is_expected.to create_directory('/opt/test/.ssh').with(
      mode: '0700',
      owner: 'test_user_2',
      group: 'nobody'
    )
  end

  keys.each do |k|
    it do
      is_expected.to edit_line_append_if_no_line("test_user_2-#{k['sum']}").with(
        path: '/opt/test/.ssh/authorized_keys',
        line: k['name'],
        owner: 'test_user_2',
        group: 'nobody'
      )
    end
  end

  it do
    is_expected.to edit_line_delete_lines('test_user_3-1388ac75').with(
      path: '/home/test_user_3/.ssh/authorized_keys',
      pattern: eq(/^key_2$/)
    )
  end

  it do
    is_expected.to edit_line_delete_lines('test_user_3-f6e240e2').with(
      path: '/home/test_user_3/.ssh/authorized_keys',
      pattern: eq(/^ssh\-ed25519\ AAAA\+plus\ test@example\.org$/)
    )
  end

  it do
    is_expected.to_not delete_directory('/home/test_user_3/.ssh')
  end

  it do
    is_expected.to_not delete_file('/home/test_user_3/.ssh/authorized_keys')
  end

  context 'exclusive and non-exclusive on one file' do
    recipe do
      osl_authorized_keys 'excl' do
        key 'key_1'
        user 't1'
        dir_path '/opt/t/.ssh/'
        exclusive true
      end

      osl_authorized_keys 'plain' do
        key 'key_2'
        user 't1'
        dir_path '/opt/t/.ssh'
        exclusive false
      end
    end

    it 'raises and leaves the file unwritten' do
      expect { chef_run }.to raise_error(
        RuntimeError,
        %r{osl_authorized_keys\[excl\].*osl_authorized_keys\[plain\].*/opt/t/\.ssh/authorized_keys}
      )
      file = chef_runner.find_resource(:file, 'osl_authorized_keys /opt/t/.ssh/authorized_keys')
      expect(file.performed_actions).to_not include(:create)
    end
  end

  context 'exclusive declarations with different groups' do
    recipe do
      osl_authorized_keys 'key_1' do
        user 't2'
        exclusive true
      end

      osl_authorized_keys 'key_2' do
        user 't2'
        group 'other'
        exclusive true
      end
    end

    it do
      expect { chef_run }.to raise_error(
        RuntimeError,
        %r{osl_authorized_keys\[key_1\].*osl_authorized_keys\[key_2\].*/home/t2/\.ssh/authorized_keys.*different user or group}
      )
    end
  end

  context 'exclusive with an empty key list' do
    recipe do
      osl_authorized_keys 't3' do
        key []
        user 't3'
      end
    end

    it 'warns and leaves the file alone' do
      allow(Chef::Log).to receive(:warn).and_call_original
      expect(Chef::Log).to receive(:warn).with(%r{osl_authorized_keys\[t3\].*no keys for /home/t3/\.ssh/authorized_keys})
      expect { chef_run }.to_not raise_error
      expect(chef_run.find_resource(:file, 'osl_authorized_keys /home/t3/.ssh/authorized_keys')).to be_nil
    end
  end

  context 'exclusive with only blank keys' do
    recipe do
      osl_authorized_keys 't3' do
        key ['', "\n"]
        user 't3'
      end
    end

    it 'warns and leaves the file alone' do
      allow(Chef::Log).to receive(:warn).and_call_original
      expect(Chef::Log).to receive(:warn).with(%r{osl_authorized_keys\[t3\].*no keys for /home/t3/\.ssh/authorized_keys})
      expect { chef_run }.to_not raise_error
      expect(chef_run.find_resource(:file, 'osl_authorized_keys /home/t3/.ssh/authorized_keys')).to be_nil
    end
  end

  context 'exclusive in a per-key loop' do
    recipe do
      %w(key_a key_b).each do |k|
        osl_authorized_keys 'same' do
          key k
          user 't4'
        end
      end
    end

    it do
      is_expected.to create_file('osl_authorized_keys /home/t4/.ssh/authorized_keys').with(content: "key_a\nkey_b\n")
    end
  end

  context 'exclusive add and remove on one file' do
    before do
      allow(Dir).to receive(:empty?).with('/home/t5/.ssh').and_return(false)
      allow(File).to receive(:empty?).with('/home/t5/.ssh/authorized_keys').and_return(false)
    end

    recipe do
      osl_authorized_keys 'key_1' do
        user 't5'
        exclusive true
      end

      osl_authorized_keys 'key_2' do
        user 't5'
        action :remove
      end
    end

    it { expect { chef_run }.to_not raise_error }
    it { is_expected.to create_file('osl_authorized_keys /home/t5/.ssh/authorized_keys').with(content: "key_1\n") }
  end

  context 'remove before the exclusive add' do
    before do
      allow(Dir).to receive(:empty?).with('/home/t7/.ssh').and_return(false)
      allow(File).to receive(:empty?).with('/home/t7/.ssh/authorized_keys').and_return(false)
    end

    recipe do
      osl_authorized_keys 'key_2' do
        user 't7'
        action :remove
      end

      osl_authorized_keys 't7' do
        key %w(key_1 key_2 key_3)
        user 't7'
      end
    end

    it { is_expected.to create_file('osl_authorized_keys /home/t7/.ssh/authorized_keys').with(content: "key_1\nkey_3\n") }
  end

  context 'remove after the exclusive add, with an empty directory' do
    before do
      allow(Dir).to receive(:empty?).with('/home/t8/.ssh').and_return(true)
      allow(File).to receive(:empty?).with('/home/t8/.ssh/authorized_keys').and_return(true)
    end

    recipe do
      osl_authorized_keys 't8' do
        key %w(key_1 key_2 key_3)
        user 't8'
      end

      osl_authorized_keys 'key_2' do
        user 't8'
        action :remove
      end
    end

    it { is_expected.to create_file('osl_authorized_keys /home/t8/.ssh/authorized_keys').with(content: "key_1\nkey_3\n") }
    it { is_expected.to_not delete_directory('/home/t8/.ssh') }
    it { is_expected.to_not delete_file('/home/t8/.ssh/authorized_keys') }
  end

  context 'add and remove on one exclusive resource' do
    before do
      allow(Dir).to receive(:empty?).with('/home/t9/.ssh').and_return(true)
      allow(File).to receive(:empty?).with('/home/t9/.ssh/authorized_keys').and_return(false)
    end

    recipe do
      osl_authorized_keys 't9' do
        key %w(key_1 key_2)
        user 't9'
        action [:add, :remove]
      end
    end

    it { is_expected.to_not create_file('osl_authorized_keys /home/t9/.ssh/authorized_keys') }
    it { is_expected.to delete_directory('/home/t9/.ssh') }
  end

  context 'exclusive next to a plain file resource on the same path' do
    recipe do
      file '/home/t6/.ssh/authorized_keys' do
        content "stray\n"
        action :create_if_missing
      end

      osl_authorized_keys 'key_1' do
        user 't6'
        exclusive true
      end
    end

    it { is_expected.to create_if_missing_file('/home/t6/.ssh/authorized_keys').with(content: "stray\n") }
    it do
      is_expected.to create_file('osl_authorized_keys /home/t6/.ssh/authorized_keys').with(
        path: '/home/t6/.ssh/authorized_keys',
        content: "key_1\n"
      )
    end
  end
end
