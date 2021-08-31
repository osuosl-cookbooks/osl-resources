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
  it do
    %w(key_1 key_2 key_3).each do |k|
      is_expected.to edit_line_append_if_no_line("test_user_1-#{k}").with(
        path: '/home/test_user_1/.ssh/authorized_keys',
        line: k,
        owner: 'test_user_1',
        group: 'test_user_1'
      )
    end
  end
  it do
    %w(key_1 key_2 key_3).each do |k|
      is_expected.to edit_line_delete_lines("test_user_1-#{k}").with(
        path: '/home/test_user_1/.ssh/authorized_keys',
        pattern: "^#{k}$"
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
  it do
    %w(key_1 key_2 key_3).each do |k|
      is_expected.to edit_line_append_if_no_line("test_user_2-#{k}").with(
        path: '/opt/test/.ssh/authorized_keys',
        line: k,
        owner: 'test_user_2',
        group: 'nobody'
      )
    end
  end

  it do
    %w(key_2).each do |k|
      is_expected.to edit_line_delete_lines("test_user_3-#{k}").with(
        path: '/home/test_user_3/.ssh/authorized_keys',
        pattern: "^#{k}$"
      )
    end
  end
  it do
    is_expected.to_not delete_directory('/home/test_user_3/.ssh')
  end
  it do
    is_expected.to_not delete_file('/home/test_user_3/.ssh/authorized_keys')
  end
end
