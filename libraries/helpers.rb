module OSLResources
  module Cookbook
    module Helpers
      require 'ipaddr'
      require 'iniparse'

      def osl_systemd_unit_enabled?(unit)
        require 'mixlib/shellout'
        begin
          unit_status = Mixlib::ShellOut.new("/bin/systemctl is-enabled #{unit}")
          unit_status.run_command
          unit_status.error!

          if unit_status.stdout.match(/enabled/)
            true
          else
            false
          end
        rescue Mixlib::ShellOut::ShellCommandFailed
          false
        end
      end

      # TODO: Workaround the following upstream issue:
      # https://github.com/chef/chef/issues/11742
      def osl_systemd_unit_enable(unit)
        execute "systemctl enable #{unit}" unless osl_systemd_unit_enabled?(unit)
      end

      # osl_ifconfig helpers
      def default_nm_controlled
        node['platform_version'].to_i >= 8 ? 'yes' : 'no'
      end

      # Based on https://github.com/chef/chef/blob/61a8aa44ac33fc3bbeb21fa33acf919a97272eb7/lib/chef/resource/systemd_unit.rb#L66-L83
      def to_ini(content)
        case content
        when Hash
          IniParse.gen do |doc|
            content.each_pair do |sect, opts|
              doc.section(sect) do |section|
                opts.each_pair do |opt, val|
                  [val].flatten.each do |v|
                    section.option(opt, v)
                  end
                end
              end
            end
          end.to_s
        else
          IniParse.parse(content.to_s).to_s
        end
      end

      def virtualbox_package_name
        case node['platform_family']
        when 'rhel'
          'VirtualBox'
        when 'debian'
          'virtualbox'
        end
      end

      def virtualbox_packages
        case node['platform_family']
        when 'rhel'
          [
            "kernel-devel-#{node['kernel']['release']}",
            'elfutils-libelf-devel',
          ]
        when 'debian'
          [
            'libelf-dev',
            "linux-headers-#{node['kernel']['release']}",
          ]
        end
      end

      def osl_local_ipv4?
        local = false
        ip = IPAddr.new(node['ipaddress'])
        osl_local_ip.each do |net|
          net = IPAddr.new net
          local = net.include?(ip)
          break if local
        end
        local
      end

      def osl_local_ipv6?
        # If we don't have an IPv6, let's just assume it's false
        return false unless node['ip6address']

        local = false
        ip = IPAddr.new(node['ip6address'])
        osl_local_ip.each do |net|
          net = IPAddr.new net
          local = net.include?(ip)
          break if local
        end
        local
      end

      private

      def dnsdist_servers(servers)
        s = {}
        servers.each do |server, option|
          i = ["address='#{server}'"]
          option.each do |opt, val|
            if val.instance_of?(String)
              i.push "#{opt}='#{val}'"
            else
              i.push "#{opt}=#{val}"
            end
          end
          s[server] = i.sort.join(', ')
        end
        s
      end

      def dnsdist_netmask_groups
        nmg = []
        if new_resource.netmask_groups
          new_resource.netmask_groups.sort.each do |name, networks|
            nmg.push "#{name} = newNMG()"
            networks.sort.each do |network|
              nmg.push "#{name}:addMask('#{network}')"
            end
          end
        end
        nmg.join("\n")
      end

      def dnsdist_service
        "dnsdist@#{new_resource.name}.service"
      end

      def dnsdist_ver
        new_resource.version.gsub('.', '')
      end

      def osl_local_ip
        # These are local to the OSU campus
        [
          '10.0.0.0/23',
          '10.1.0.0/23',
          '10.1.2.0/23',
          '10.1.100.0/22',
          '10.6.4.0/22',
          '10.162.136.0/24',    # Milne Workstation subnet
          '128.193.126.192/28', # Milne Server subnet
          '128.193.152.128/27', # OSU Gateway from Milne workstations
          '140.211.9.0/24',
          '140.211.10.0/24',
          '140.211.15.0/24',
          '140.211.166.0/23',
          '140.211.168.0/24',
          '140.211.169.0/24',
          '2605:bc80:3010::/48',
        ]
      end

      def awstats_default_log_format
        %w(
          %virtualname
          %host
          %other
          %logname
          %time1
          %methodurl
          %code
          %bytesd
          %refererquot
          %uaquot
          %other
        )
      end

      def array_to_string(val)
        val.is_a?(Array) ? val.join(' ') : val
      end
    end
  end
end
Chef::DSL::Recipe.include ::OSLResources::Cookbook::Helpers
Chef::Resource.include ::OSLResources::Cookbook::Helpers
# Needed to used in attributes/
Chef::Node.include ::OSLResources::Cookbook::Helpers
