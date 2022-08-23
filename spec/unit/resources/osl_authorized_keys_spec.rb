require_relative '../../spec_helper'

describe 'osl_authorized_keys' do
  platform 'centos'
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
        action [:add, :remove]
      end
    end

    %w(key_1 key_2 key_3).each do |k|
      osl_authorized_keys k do
        user 'test_user_2'
        group 'nobody'
        dir_path '/opt/test/.ssh'
      end
    end

    osl_authorized_keys 'key_2' do
      user 'test_user_3'
      action :remove
    end
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
        pattern: "^#{k['name']}$"
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
      pattern: '^key_2$'
    )
  end

  it do
    is_expected.to_not delete_directory('/home/test_user_3/.ssh')
  end

  it do
    is_expected.to_not delete_file('/home/test_user_3/.ssh/authorized_keys')
  end
end
