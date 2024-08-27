module OSLResources
  module Cookbook
    module ResourceHelpers
      def osl_udev_rules_resource_init
        osl_udev_rules_resource_create unless osl_udev_rules_resource_exist?
      end

      def osl_udev_rules_resource
        return unless osl_udev_rules_resource_exist?

        find_resource!(:template, '/etc/udev/rules.d/99-chef.rules')
      end

      private

      def osl_udev_rules_resource_exist?
        !find_resource!(:template, '/etc/udev/rules.d/99-chef.rules').nil?
      rescue Chef::Exceptions::ResourceNotFound
        false
      end

      def osl_udev_rules_resource_create
        with_run_context(:root) do
          declare_resource(:execute, 'trigger udev') do
            command '/bin/udevadm trigger'

            action :nothing
            delayed_action :nothing
          end

          declare_resource(:execute, 'reload udev') do
            command '/bin/udevadm control --reload'

            action :nothing
            delayed_action :nothing
            notifies :run, 'execute[trigger udev]', :immediately
          end

          declare_resource(:template, '/etc/udev/rules.d/99-chef.rules') do
            cookbook 'osl-resources'
            source 'rules.erb'

            helpers(OSLResources::Cookbook::TemplateHelpers)

            action :nothing
            delayed_action :create
            notifies :run, 'execute[reload udev]', :immediately unless docker?
            notifies :run, 'execute[dracut -f]' unless docker?
          end

          declare_resource(:directory, '/etc/dracut.conf.d') do
            action :nothing
            delayed_action :create
          end

          declare_resource(:execute, 'dracut -f') do
            action :nothing
            delayed_action :nothing
          end

          declare_resource(:file, '/etc/dracut.conf.d/chef-rules.conf') do
            content 'install_items+=" /etc/udev/rules.d/99-chef.rules "'

            action :nothing
            delayed_action :create
            notifies :run, 'execute[dracut -f]' unless docker?
          end
        end
      end
    end
  end
end
