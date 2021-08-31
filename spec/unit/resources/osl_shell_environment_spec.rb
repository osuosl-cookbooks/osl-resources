require 'spec_helper'

describe 'osl_shell_environment' do
  recipe do
    osl_shell_environment 'EDITOR' do
      value 'vim'
    end

    osl_shell_environment 'remove' do
      action :remove
    end
  end

  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      platform p[:platform], p[:version]
      cached(:subject) { chef_run }
      step_into :osl_shell_environment

      it do
        is_expected.to create_file('/etc/profile.d/EDITOR.sh')
          .with(
            owner: 'root',
            group: 'root',
            mode: '0644',
            sensitive: false,
            content: <<-EOF.gsub(/^\s{14}/, '')
              #
              # This file was generated by Chef
              # Do NOT modify this file by hand!
              #
              export EDITOR="vim"
              EOF
          )
      end
      it do
        is_expected.to delete_file('/etc/profile.d/remove.sh')
      end
    end
  end
end
