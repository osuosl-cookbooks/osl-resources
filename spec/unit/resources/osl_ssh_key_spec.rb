require_relative '../../spec_helper'

describe 'osl_ssh_key' do
  platform 'centos'
  step_into :osl_ssh_key

  before do
    allow(Dir).to receive(:empty?).with('/home/test_user_1/.ssh').and_return(true)
    allow(Dir).to receive(:empty?).with('/home/test_user_3/.ssh').and_return(false)
  end

  recipe do
    osl_ssh_key 'id_rsa' do
      user 'test_user_1'
      key 'test_key'
      action [:add, :remove]
    end

    osl_ssh_key 'id_ed25519' do
      user 'test_user_2'
      group 'nobody'
      dir_path '/opt/test/.ssh'
      key 'curvy_key'
    end

    osl_ssh_key 'id_rsa' do
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
    is_expected.to create_file('/home/test_user_1/.ssh/id_rsa').with(
      content: 'test_key',
      mode: '0600',
      owner: 'test_user_1',
      group: 'test_user_1'
    )
  end
  it do
    is_expected.to delete_directory('/home/test_user_1/.ssh')
  end
  it do
    is_expected.to delete_file('/home/test_user_1/.ssh/id_rsa')
  end

  it do
    is_expected.to create_directory('/opt/test/.ssh').with(
      mode: '0700',
      owner: 'test_user_2',
      group: 'nobody'
    )
  end
  it do
    is_expected.to create_file('/opt/test/.ssh/id_ed25519').with(
      content: 'curvy_key',
      mode: '0600',
      owner: 'test_user_2',
      group: 'nobody'
    )
  end
  it do
    is_expected.to_not delete_directory('/home/test_user_3/.ssh')
  end
  it do
    is_expected.to delete_file('/home/test_user_3/.ssh/id_rsa')
  end
end
