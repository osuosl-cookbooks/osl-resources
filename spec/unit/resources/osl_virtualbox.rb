require 'spec_helper'

describe 'osl_virtualbox' do
  recipe do
    osl_virtualbox '6.1'
  end

  context 'almalinux' do
    platform 'almalinux'
    cached(:subject) { chef_run }
    step_into :osl_virtualbox

    it do
      is_expected.to create_yum_repository('virtualbox')
        .with(
          description: 'VirtualBox - 6.1',
          baseurl: 'http://download.virtualbox.org/virtualbox/rpm/el/$releasever/$basearch',
          repo_gpgcheck: true,
          gpgcheck: true,
          gpgkey: %w(
            https://www.virtualbox.org/download/oracle_vbox_2016.asc
            https://www.virtualbox.org/download/oracle_vbox.asc
          )
        )
    end
    it { is_expected.to unload_kernel_module('kvm_amd') }
    it { is_expected.to unload_kernel_module('kvm_intel') }
    it { is_expected.to unload_kernel_module('kvm') }
    it { is_expected.to blacklist_kernel_module('kvm_amd') }
    it { is_expected.to blacklist_kernel_module('kvm_intel') }
    it { is_expected.to blacklist_kernel_module('kvm') }
    it { is_expected.to install_build_essential('osl_virtualbox') }
    it { is_expected.to install_package(%w(kernel-devel-4.18.0-193.6.3.el8_2.x86_64 elfutils-libelf-devel)) }
    it { is_expected.to install_package('VirtualBox-6.1') }
  end

  context 'debian' do
    platform 'debian'
    cached(:subject) { chef_run }
    step_into :osl_virtualbox

    it do
      is_expected.to add_apt_repository('virtualbox')
        .with(
          uri: 'https://download.virtualbox.org/virtualbox/debian',
          ignore_failure: true,
          key: %w(
            https://www.virtualbox.org/download/oracle_vbox_2016.asc
            https://www.virtualbox.org/download/oracle_vbox.asc
          ),
          components: %w(contrib)
        )
    end
    it { is_expected.to unload_kernel_module('kvm_amd') }
    it { is_expected.to unload_kernel_module('kvm_intel') }
    it { is_expected.to unload_kernel_module('kvm') }
    it { is_expected.to blacklist_kernel_module('kvm_amd') }
    it { is_expected.to blacklist_kernel_module('kvm_intel') }
    it { is_expected.to blacklist_kernel_module('kvm') }
    it { is_expected.to install_build_essential('osl_virtualbox') }
    it { is_expected.to install_package(%w(libelf-dev linux-headers-5.10.0-9-cloud-amd64)) }
    it { is_expected.to install_package('virtualbox-6.1') }
  end
end
