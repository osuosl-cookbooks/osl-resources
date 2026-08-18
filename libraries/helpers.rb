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
        'yes'
      end

      def default_nmstate
        node['platform_version'].to_i >= 9
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

      def virtualbox_gpg
        if platform_family?('rhel')
          if node['platform_version'].to_i >= 10
            %w(https://www.virtualbox.org/download/oracle_vbox_2016.asc)
          else
            %w(
              https://www.virtualbox.org/download/oracle_vbox_2016.asc
              https://www.virtualbox.org/download/oracle_vbox.asc
            )
          end
        elsif platform?('debian')
          %w(https://www.virtualbox.org/download/oracle_vbox_2016.asc)
        else
          %w(
            https://www.virtualbox.org/download/oracle_vbox_2016.asc
            https://www.virtualbox.org/download/oracle_vbox.asc
          )
        end
      end

      def mongodb_baseurl
        case node['platform_version'].to_i
        when 10
          "https://repo.mongodb.org/yum/redhat/9/mongodb-org/#{new_resource.version}/$basearch/"
        else
          "https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/#{new_resource.version}/$basearch/"
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

      # The extended Hugo build is cgo-linked, so unlike the standard build it
      # needs libstdc++ (and libgcc, which libstdc++ pulls in) at runtime.
      def hugo_packages
        case node['platform_family']
        when 'rhel'
          %w(tar libstdc++)
        when 'debian'
          %w(tar libstdc++6)
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

      # Renders the complete site block(s) from a content hash.
      #
      # @param content_hash [Hash] The main hash defining site(s).
      #   Example:
      #   {
      #     "example.com, www.example.com": { ... directives ... },
      #     "another.example.net": { ... directives ... }
      #   }
      # @return [String] The complete Caddyfile content for the site(s).
      def render_caddy_site_from_hash(content_hash)
        output = []
        content_hash.each do |site_address_block, directives|
          output << "#{site_address_block} {"
          output << render_caddy_directives(directives, 1) # Start directives at indent level 1
          output << '}'
        end
        output.join("\n")
      end

      # Get latest version of repo release from Github
      def osl_github_latest_version(repo, version, key = 'name')
        releases = []
        uri = URI("https://api.github.com/repos/#{repo}/releases")
        response = JSON.parse(Net::HTTP.get(uri))
        response.each do |rel|
          # Match version given
          if rel[key].match?(/^v#{version}/)
            # Remove leading 'v' from name
            releases << rel[key][1..-1]
          elsif rel[key].match?(/^#{version}/)
            releases << rel[key]
          end
        end
        # First one should be latest
        releases.first
      end

      def osl_anubis_default_bots
        %w(
          (data)/bots/_deny-pathological.yaml
          (data)/bots/aggressive-brazilian-scrapers.yaml
          (data)/meta/ai-block-aggressive.yaml
          (data)/crawlers/_allow-good.yaml
          (data)/clients/x-firefox-ai.yaml
          (data)/common/keep-internet-working.yaml
        )
      end

      private

      def ifconfig_type
        case new_resource.type
        when 'linux-bridge'
          'Bridge'
        when 'bond'
          'Bond'
        when nil
          # nmstate infers the bond type from bonding_opts; ifcfg must be told.
          new_resource.bonding_opts ? 'Bond' : nil
        else
          new_resource.type
        end
      end

      # Resolve each address to an explicit { ipaddress, prefix } pair. Prefix
      # comes from a CIDR suffix, else `mask`. IPAddr's default of /32 leaves
      # the interface up with no on-link subnet route, so it is not used.
      def nmstate_ipaddrs(ips)
        return unless ips
        masks = Array(new_resource.mask)
        Array(ips).each_with_index.map do |addr, idx|
          return nil unless addr
          ipaddress, cidr = addr.to_s.split('/')
          prefix = cidr || nmstate_mask_for(ipaddress, masks, idx)
          if prefix.nil?
            # IPv4 has no safe default; IPv6 does, since ifcfg-rh has always
            # read a bare IPV6ADDR as /64.
            if IPAddr.new(ipaddress).ipv4?
              raise "osl_ifconfig[#{new_resource.device}]: no mask or CIDR prefix for #{addr}. " \
                    'Set the `mask` property or write the address as <address>/<prefix>.'
            end
            Chef::Log.warn(
              "osl_ifconfig[#{new_resource.device}]: no CIDR prefix for #{addr}, assuming /64. " \
              'Write the address as <address>/<prefix> to be explicit.'
            )
            prefix = 64
          end
          { ipaddress: IPAddr.new(ipaddress).to_s, prefix: IPAddr.new("#{ipaddress}/#{prefix}").prefix }
        end
      end

      # `mask` holds IPv4 dotted netmasks, so IPv6 never consults it. A lone
      # mask covers every address; otherwise they line up positionally.
      def nmstate_mask_for(ipaddress, masks, idx)
        return if masks.empty?
        return unless IPAddr.new(ipaddress).ipv4?
        masks[idx] || (masks.one? ? masks.first : nil)
      end

      # A next hop takes no prefix, and ifcfg-rh rejects one outright, but the
      # documented examples write gateways with one.
      def nmstate_gateway_addr(gateway)
        return if gateway.nil?
        IPAddr.new(gateway.to_s.split('/').first).to_s
      end

      # Member-side membership: ifcfg BRIDGE=/MASTER=, nmstate `controller:`.
      def nmstate_controller
        new_resource.bridge || new_resource.master
      end

      def nmstate_state
        if new_resource.onboot == 'yes'
          'up'
        else
          'down'
        end
      end

      def nmstate_ipv6_autoconf
        new_resource.ipv6_autoconf == 'yes'
      end

      # nmstate refuses autoconf without DHCP, so SLAAC needs both.
      def nmstate_ipv6_dhcp
        nmstate_ipv6_autoconf
      end

      # nmstate disables IPv6 unless told otherwise, stripping SLAAC and the
      # link-local address. Honour what the recipe stated.
      def nmstate_ipv6_enabled?
        return true unless Array(new_resource.ipv6addr).empty?
        return true unless Array(new_resource.ipv6addrsec).empty?
        return true if new_resource.ipv6init == 'yes'
        return true if new_resource.ipv6_autoconf == 'yes'
        return true if new_resource.ipv6_defaultgw
        false
      end

      def nmstate_vlan_device
        new_resource.device.split('.').first
      end

      def nmstate_vlan_id
        new_resource.device.split('.')[1]
      end

      def nmstate_bonding_opts
        return unless new_resource.bonding_opts
        opts = {}
        new_resource.bonding_opts.split(' ').each do |opt|
          k, v = opt.split('=', 2)
          next if v.nil?
          # Coercing every value turned mode=active-backup into 0 (balance-rr)
          # and mode=802.3ad into 802.
          opts[k.to_sym] = v.match?(/\A-?\d+\z/) ? v.to_i : v
        end
        opts
      end

      def nmstate_routes
        new_resource.routes.map do |route|
          # Translate netmask to CIDR
          {
            destination: "#{route[:address]}/#{netmask_to_cidr(route[:netmask])}",
            next_hop_interface: new_resource.device,
            next_hop_address: route[:gateway],
          }
        end
      end

      def netmask_to_cidr(netmask)
        IPAddr.new(netmask, Socket::AF_INET).to_i.to_s(2).count('1')
      end

      def chrony_service
        platform_family?('rhel') ? 'chronyd' : 'chrony'
      end

      def chrony_conf_path
        platform_family?('rhel') ? '/etc/chrony.conf' : '/etc/chrony/chrony.conf'
      end

      # Key-based (server) setups are RHEL-only
      def chrony_keyfile
        '/etc/chrony.keys'
      end

      def chrony_group
        'chrony'
      end

      # time.osuosl.org is a DNS round-robin over the internal NTP servers;
      # the pool directive makes chrony use all of its addresses and replace
      # any that become unreachable. 2.pool.ntp.org (the subdomain with AAAA
      # records) is the external fallback.
      def chrony_default_pools
        {
          'time.osuosl.org' => 'iburst maxsources 3',
          '2.pool.ntp.org' => 'iburst maxsources 2',
        }
      end

      def chrony_default_conf
        {
          'driftfile' => platform_family?('rhel') ? '/var/lib/chrony/drift' : '/var/lib/chrony/chrony.drift',
          'makestep' => '1.0 3',
          'rtcsync' => nil,
          'logdir' => '/var/log/chrony',
          'port' => 0,
          'cmdport' => 0,
        }
      end

      # The client conf without the serving disabled, plus the NTP server
      # directives.
      def chrony_server_default_conf
        chrony_default_conf.reject { |k, _| %w(port cmdport).include?(k) }.merge(
          'local' => 'stratum 10 orphan',
          'leapsectz' => 'right/UTC',
          'ntsdumpdir' => '/var/lib/chrony',
          'ratelimit' => 'interval 1 burst 16'
        )
      end

      # Every address in the ntp_servers map except this node's own entry.
      def chrony_peers(ntp_servers)
        ntp_servers.reject { |host, _| host == node['hostname'] }.values.flatten
      end

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

      def nmstatectl_cmd
        if node['platform_version'].to_i >= 9
          'nmstatectl apply -q'
        else
          'nmstatectl apply'
        end
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

      # Renders a hash of Caddy directives into Caddyfile string format.
      #
      # @param directives [Hash] The hash of directives.
      #   Example:
      #   {
      #     "root" => "* /srv/www/example",
      #     "file_server" => true,
      #     "log" => {
      #       "output" => "file /var/log/caddy/example.com.access.log",
      #       "format" => "json"
      #     },
      #     "custom_block" => ["header X-My-Header MyValue"]
      #   }
      # @param indent_level [Integer] The current indentation level.
      # @return [String] The formatted Caddyfile directives.
      def render_caddy_directives(directives_hash, indent_level = 0)
        output = []
        indent = '  ' * indent_level # Two spaces per indent level

        directives_hash.each do |key, value|
          directive_name = key.to_s # Ensure directive name is a string

          case value
          when Hash # It's a block
            output << "#{indent}#{directive_name} {"
            output << render_caddy_directives(value, indent_level + 1) # Recurse
            output << "#{indent}}"
          when Array # Assumed to be an array of arguments or raw lines
            # If the key suggests it's a container for raw lines (e.g., 'raw_lines') then each element of the array is
            # a full line.  Otherwise, each element is an argument to the directive_name.  This heuristic might need
            # refinement based on your specific hash conventions.
            if %w(raw_lines).include?(directive_name.downcase)
              value.each { |line| output << "#{indent}#{line}" }
            else
              # If it's a simple array of arguments for a single directive.  Caddyfile syntax for multiple arguments
              # is usually space-separated on one line.  If the array represents multiple separate invocations of the
              # same directive, this logic would need to change. For now, assume space-separated args.
              # Example: "header" => ["X-Header Value", "Cache-Control none"] -> header X-Header Value \n header
              # Cache-Control none
              # Or "directive" => ["arg1", "arg2"] -> directive arg1 arg2
              # Let's assume if value is an array, each element is a *separate* invocation or a full line for that
              # directive
              value.each do |line_or_arg|
                output << "#{indent}#{directive_name} #{line_or_arg}"
              end
            end
          when true, false, nil # Directive without arguments
            output << "#{indent}#{directive_name}"
          else # String, Numeric, or other simple value
            output << "#{indent}#{directive_name} #{value}"
          end
        end
        output.join("\n")
      end

      def array_to_string(val)
        val.is_a?(Array) ? val.join(' ') : val
      end

      def copr_enabled?(copr)
        repo_file = "/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:#{copr.tr('/', ':')}.repo"
        ::File.exist?(repo_file)
      end

      # osl_test_netns helpers. Wrap `ip` lookups so the resource can use
      # Ruby `not_if`/`only_if` blocks instead of shelling out from a string.

      def osl_netns_exists?(name)
        require 'mixlib/shellout'
        cmd = Mixlib::ShellOut.new('ip', 'netns', 'list')
        cmd.run_command
        return false unless cmd.exitstatus.zero?
        cmd.stdout.each_line.any? { |line| line.split(/\s+/).first == name }
      end

      def osl_netns_link_exists?(iface, netns: nil)
        !osl_netns_link_show(iface, netns: netns).nil?
      end

      # True when the interface's admin flag is UP (operational state may
      # still be LOWERLAYERDOWN if the peer isn't up yet, which is fine for
      # idempotency, since `ip link set X up` is a no-op when already admin-up).
      def osl_netns_link_admin_up?(iface, netns: nil)
        out = osl_netns_link_show(iface, netns: netns)
        return false if out.nil?
        out.match?(/<[^>]*\bUP\b[^>]*>/)
      end

      def osl_netns_link_has_addr?(iface, addr, netns: nil)
        require 'mixlib/shellout'
        args = ['ip']
        args += ['-n', netns] if netns
        args += ['-o', 'addr', 'show', 'dev', iface]
        cmd = Mixlib::ShellOut.new(*args)
        cmd.run_command
        return false unless cmd.exitstatus.zero?
        cmd.stdout.include?(addr)
      end

      def osl_netns_link_has_mac?(iface, mac, netns: nil)
        out = osl_netns_link_show(iface, netns: netns)
        return false if out.nil?
        out.downcase.include?(mac.downcase)
      end

      def osl_netns_link_is_type?(iface, type)
        require 'mixlib/shellout'
        cmd = Mixlib::ShellOut.new('ip', '-details', 'link', 'show', 'dev', iface)
        cmd.run_command
        return false unless cmd.exitstatus.zero?
        cmd.stdout.match?(/^\s+#{Regexp.escape(type)}\s/)
      end

      # Returns the `ip -o link show dev <iface>` output (the "-o" form
      # collapses each interface to one line, including the link/ether
      # detail). Returns nil when the interface or netns doesn't exist.
      def osl_netns_link_show(iface, netns: nil)
        require 'mixlib/shellout'
        args = ['ip']
        args += ['-n', netns] if netns
        args += ['-o', 'link', 'show', 'dev', iface]
        cmd = Mixlib::ShellOut.new(*args)
        cmd.run_command
        cmd.exitstatus.zero? ? cmd.stdout : nil
      end

      # osl_sysfs_param helpers. sysfs entries are not regular files, so the
      # file resource's content staging, backup and atomic rename machinery
      # does not work against them. Read and write them with native Ruby file
      # methods instead.

      def osl_sysfs_param_read(path)
        ::File.read(path).strip
      end

      # Compares stripped values so a parameter that reads back without a
      # trailing newline still converges exactly once.
      def osl_sysfs_param_has_value?(path, value)
        osl_sysfs_param_read(path) == value.to_s.strip
      end

      # A trailing newline matches what writing the parameter with echo would
      # produce, which is what the kernel's parameter parsers expect.
      def osl_sysfs_param_write(path, value)
        ::File.write(path, "#{value}\n")
      end

      # Deterministic per-parameter fragment path, so `persist false` can
      # clean up the same file `persist true` created.
      def osl_sysfs_param_tmpfiles_path(path)
        "/etc/tmpfiles.d/chef-#{path.delete_prefix('/').tr('/', '-')}.conf"
      end

      # A tmpfiles.d `w` line: write the argument to the path at boot, if the
      # path exists then. The argument field is subject to %-specifier
      # expansion and C-style backslash escapes, so escape both.
      def osl_sysfs_param_tmpfiles_line(path, value)
        escaped = value.to_s.gsub('\\') { '\\\\' }.gsub('%', '%%')
        "w #{path} - - - - #{escaped}\n"
      end

      # osl_fakenic helpers

      # Deterministic per-interface unit name, so `persist false` and :delete
      # clean up the same unit `persist true` created.
      def osl_fakenic_unit_name(interface)
        "osl-fakenic-#{interface.gsub(/[^A-Za-z0-9:_.-]/, '-')}.service"
      end

      def osl_fakenic_unit_path(interface)
        "/etc/systemd/system/#{osl_fakenic_unit_name(interface)}"
      end

      # systemd needs an absolute path, and `ip` is not in the same place
      # everywhere: /usr/sbin on RHEL, /usr/bin on Debian with only a
      # compatibility symlink at /usr/sbin. Resolve it rather than guess.
      def osl_fakenic_ip_path
        which('ip') || '/usr/sbin/ip'
      end

      # Recreates the device and nothing else, leaving addressing on top to
      # whatever manages it. NetworkManager, network.service and
      # systemd-networkd all order themselves After=network-pre.target, so
      # running before it is what guarantees the device exists first.
      #
      # Every ExecStart is idempotent -- `-` on the add, `addr replace` rather
      # than `addr add` -- so the unit can also be started by the converge that
      # writes it. There is deliberately no ExecStop: stopping the unit must
      # never take an interface down under osl_ifconfig.
      def osl_fakenic_unit_content(interface:, ip_path:, ip4: nil, ip6: nil, mac_address: nil, multicast: false)
        cmds = ["-#{ip_path} link add name #{interface} type dummy"]
        cmds << "#{ip_path} link set dev #{interface} address #{mac_address}" if mac_address
        cmds << "#{ip_path} link set dev #{interface} multicast on" if multicast
        cmds << "#{ip_path} link set dev #{interface} up"
        Array(ip4).each { |ip| cmds << "#{ip_path} addr replace #{ip} dev #{interface}" }
        Array(ip6).each { |ip| cmds << "#{ip_path} -6 addr replace #{ip} dev #{interface}" }

        <<~EOU
          [Unit]
          Description=Fake dummy interface #{interface}
          Wants=network-pre.target
          Before=network-pre.target NetworkManager.service

          [Service]
          Type=oneshot
          RemainAfterExit=yes
          #{cmds.map { |c| "ExecStart=#{c}" }.join("\n")}

          [Install]
          WantedBy=multi-user.target
        EOU
      end
    end
  end
end
Chef::DSL::Recipe.include ::OSLResources::Cookbook::Helpers
Chef::Resource.include ::OSLResources::Cookbook::Helpers
# Needed to used in attributes/
Chef::Node.include ::OSLResources::Cookbook::Helpers
