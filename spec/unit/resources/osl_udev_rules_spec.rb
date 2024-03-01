require 'spec_helper'

describe 'osl_udev_rules' do
  context 'almalinux' do
    platform 'almalinux'
    cached(:subject) { chef_run }

    step_into :osl_udev_rules
    recipe do
      osl_udev_rules 'foo'
    end

    it { is_expected.to nothing_execute('trigger udev').with(command: '/bin/udevadm trigger') }
    it { is_expected.to nothing_execute('reload udev').with(command: '/bin/udevadm control --reload') }
    it { expect(chef_run.execute('reload udev')).to notify('execute[trigger udev]').to(:run).immediately }
    it do
      is_expected.to create_template('/etc/udev/rules.d/99-chef.rules').with(
        cookbook: 'osl-resources',
        source: 'rules.erb',
        variables: {
          'rules' => %w(foo),
        }
      )
    end
    it do
      expect(chef_run.template('/etc/udev/rules.d/99-chef.rules')).to \
        notify('execute[reload udev]').to(:run).immediately
    end
    it do
      expect(chef_run.template('/etc/udev/rules.d/99-chef.rules')).to \
        notify('execute[dracut -f]').to(:run)
    end
    it { is_expected.to create_directory('/etc/dracut.conf.d') }
    it { is_expected.to nothing_execute('dracut -f') }
    it do
      is_expected.to create_file('/etc/dracut.conf.d/chef-rules.conf').with(
        content: 'install_items+=" /etc/udev/rules.d/99-chef.rules "'
      )
    end
    it do
      expect(chef_run.file('/etc/dracut.conf.d/chef-rules.conf')).to \
        notify('execute[dracut -f]').to(:run)
    end
    it { is_expected.to_not delete_file('/etc/udev/rules.d/70-persistent-net.rules') }
    it do
      expect(chef_run.file('/etc/udev/rules.d/70-persistent-net.rules')).to_not \
        notify('execute[trigger udev]').to(:run)
    end

    context 'persistent_net false' do
      cached(:subject) { chef_run }
      recipe do
        osl_udev_rules 'bar' do
          persistent_net false
        end
      end

      it { is_expected.to delete_file('/etc/udev/rules.d/70-persistent-net.rules') }
      it do
        expect(chef_run.file('/etc/udev/rules.d/70-persistent-net.rules')).to \
          notify('execute[reload udev]').to(:run).delayed
      end
    end
  end
end
