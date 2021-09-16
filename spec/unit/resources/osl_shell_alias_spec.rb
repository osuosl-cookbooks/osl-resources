require 'spec_helper'

describe 'osl_shell_alias' do
  recipe do
    osl_shell_alias 'll' do
      command 'ls -l'
    end

    osl_shell_alias 'remove' do
      action :remove
    end
  end

  context 'centos' do
    platform 'centos'
    cached(:subject) { chef_run }
    step_into :osl_shell_alias

    it do
      is_expected.to create_file('/etc/profile.d/ll.sh')
        .with(
          mode: '0755',
          content: <<~EOF
            #
            # This file was generated by Chef
            # Do NOT modify this file by hand!
            #
            alias ll="ls -l"
          EOF
        )
    end
    it do
      is_expected.to delete_file('/etc/profile.d/remove.sh')
    end
  end
end
