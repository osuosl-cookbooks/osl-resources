require_relative '../../spec_helper'

describe 'osl_sysfs_param' do
  platform 'almalinux'
  step_into :osl_sysfs_param

  let(:param_path) { '/sys/module/nf_conntrack/parameters/hashsize' }
  let(:tmpfiles_path) { '/etc/tmpfiles.d/chef-sys-module-nf_conntrack-parameters-hashsize.conf' }
  let(:param_exists) { true }
  let(:current_content) { "16384\n" }

  before do
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:exist?).with(param_path).and_return(param_exists)
    allow(::File).to receive(:read).and_call_original
    allow(::File).to receive(:read).with(param_path).and_return(current_content)
    allow(::File).to receive(:write).and_call_original
    allow(::File).to receive(:write).with(param_path, anything).and_return(nil)
  end

  context 'current value differs' do
    recipe do
      osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
        value 32768
      end
    end

    it { is_expected.to set_osl_sysfs_param('/sys/module/nf_conntrack/parameters/hashsize').with(value: '32768') }

    it 'writes the desired value with a trailing newline' do
      chef_run
      expect(::File).to have_received(:write).with(param_path, "32768\n")
    end

    it 'removes the tmpfiles fragment when persist is not set' do
      expect(chef_run).to delete_file(tmpfiles_path)
    end
  end

  context 'persist true' do
    recipe do
      osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
        value 32768
        persist true
      end
    end

    it do
      is_expected.to create_file(tmpfiles_path).with(
        content: "w /sys/module/nf_conntrack/parameters/hashsize - - - - 32768\n",
        mode: '0644'
      )
    end
  end

  context 'persist true with a value needing tmpfiles escaping' do
    recipe do
      osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
        value '50%'
        persist true
      end
    end

    it 'escapes the percent sign against specifier expansion' do
      expect(chef_run).to create_file(tmpfiles_path).with(
        content: "w /sys/module/nf_conntrack/parameters/hashsize - - - - 50%%\n"
      )
    end
  end

  context 'persist true when the parameter is missing and ignore_missing is set' do
    let(:param_exists) { false }

    recipe do
      osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
        value 32768
        ignore_missing true
        persist true
      end
    end

    it { expect { chef_run }.to_not raise_error }

    it 'still lays down the fragment since tmpfiles w lines skip missing paths' do
      expect(chef_run).to create_file(tmpfiles_path)
    end
  end

  context 'current value already matches' do
    let(:current_content) { "32768\n" }

    recipe do
      osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
        value 32768
      end
    end

    it 'does not write the parameter' do
      chef_run
      expect(::File).to_not have_received(:write).with(param_path, anything)
    end
  end

  context 'parameter reads back without a trailing newline' do
    let(:current_content) { '32768' }

    recipe do
      osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
        value 32768
      end
    end

    it 'does not write the parameter' do
      chef_run
      expect(::File).to_not have_received(:write).with(param_path, anything)
    end
  end

  context 'value given as a String' do
    let(:current_content) { "32768\n" }

    recipe do
      osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
        value '32768'
      end
    end

    it 'does not write the parameter' do
      chef_run
      expect(::File).to_not have_received(:write).with(param_path, anything)
    end
  end

  context 'param_path given as a property instead of the resource name' do
    recipe do
      osl_sysfs_param 'nf_conntrack hashsize' do
        param_path '/sys/module/nf_conntrack/parameters/hashsize'
        value 32768
      end
    end

    it { is_expected.to set_osl_sysfs_param('nf_conntrack hashsize').with(param_path: param_path) }

    it 'writes to param_path' do
      chef_run
      expect(::File).to have_received(:write).with(param_path, "32768\n")
    end
  end

  context 'parameter does not exist' do
    let(:param_exists) { false }

    recipe do
      osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
        value 32768
      end
    end

    it do
      expect { chef_run }.to raise_error(
        Chef::Exceptions::FileNotFound,
        %r{/sys/module/nf_conntrack/parameters/hashsize does not exist}
      )
    end
  end

  context 'parameter does not exist and ignore_missing is set' do
    let(:param_exists) { false }

    recipe do
      osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
        value 32768
        ignore_missing true
      end
    end

    it { expect { chef_run }.to_not raise_error }

    it 'does not write the parameter' do
      chef_run
      expect(::File).to_not have_received(:write).with(param_path, anything)
    end
  end
end
