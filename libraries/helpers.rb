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
        releases[0]
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
        else
          new_resource.type
        end
      end

      def nmstate_ipaddrs(ips)
        return unless ips
        ipaddrs = []
        ips.each_with_index do |i, idx|
          return nil unless i
          ip = if !new_resource.mask.empty? && IPAddr.new(i).ipv4?
                 IPAddr.new("#{i}/#{new_resource.mask[idx]}")
               else
                 IPAddr.new(i)
               end
          ipaddrs << { ipaddress: IPAddr.new(i.split('/').first).to_s, prefix: ip.prefix }
        end
        ipaddrs
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

      def nmstate_vlan_device
        new_resource.device.split('.')[0]
      end

      def nmstate_vlan_id
        new_resource.device.split('.')[1]
      end

      def nmstate_bonding_opts
        return unless new_resource.bonding_opts
        opts = {}
        new_resource.bonding_opts.split(' ').each do |opt|
          opts.merge!(opt.split('=').then { |k, v| { k.to_sym => v.to_i } })
        end
        opts
      end

      def nmstate_routes
        routes = []
        new_resource.routes.each do |route|
          # Translate netmask to CIDR
          routes << {
            destination: "#{route[:address]}/#{netmask_to_cidr(route[:netmask])}",
            next_hop_interface: new_resource.device,
            next_hop_address: route[:gateway],
          }
        end
        routes
      end

      def netmask_to_cidr(netmask)
        IPAddr.new(netmask, Socket::AF_INET).to_i.to_s(2).count('1')
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

      # osl_ipmi_user helpers

      # Check if IPMI device is available
      def ipmi_available?
        ::File.exist?('/dev/ipmi0') || ::File.exist?('/dev/ipmi/0') || ::File.exist?('/dev/ipmidev/0')
      end

      # Get IPMI version from BMC (returns float like 1.5 or 2.0)
      def ipmi_version
        output = run_ipmi_command('mc info')
        if output =~ /IPMI Version\s*:\s*(\d+\.\d+)/
          Regexp.last_match(1).to_f
        else
          1.5 # Default to 1.5 if we can't detect
        end
      rescue Mixlib::ShellOut::ShellCommandFailed
        1.5 # Default to 1.5 on error
      end

      # Check if IPMI 2.0 is supported (for 20-byte passwords)
      def ipmi_supports_20_byte_password?
        ipmi_version >= 2.0
      end

      # Get maximum password length based on IPMI version
      def ipmi_max_password_length
        ipmi_supports_20_byte_password? ? 20 : 16
      end

      # Run an ipmitool command and return stdout
      def run_ipmi_command(args)
        require 'mixlib/shellout'
        cmd = Mixlib::ShellOut.new("ipmitool #{args}")
        cmd.run_command
        cmd.error!
        cmd.stdout
      end

      # Parse ipmitool user list output into an array of user hashes
      # Format:
      # ID  Name             Callin  Link Auth  IPMI Msg   Channel Priv Limit
      # 1                    false   false      false      NO ACCESS
      # 2   admin            true    true       true       ADMINISTRATOR
      def ipmi_parse_user_list(output)
        users = []
        output.each_line do |line|
          next if line.match?(/^ID\s+Name|^-+/)

          # Parse: ID  Name  Callin  Link Auth  IPMI Msg  Channel Priv Limit
          parts = line.split
          next if parts.length < 5

          slot = parts[0].to_i
          next if slot == 0

          # Username is second field, but may be empty
          # If field 1 is true/false, then username is empty (columns shift left)
          if parts[1] =~ /^(true|false)$/i
            username = ''
            # Parts: ID, Callin, Link Auth, IPMI Msg, Privilege...
            enabled = parts[3].downcase == 'true'
            privilege = parts[4..-1].join(' ')
          else
            username = parts[1]
            # Parts: ID, Name, Callin, Link Auth, IPMI Msg, Privilege...
            enabled = parts[4].downcase == 'true'
            privilege = parts[5..-1].join(' ')
          end

          users << {
            slot: slot,
            username: username,
            privilege: ipmi_privilege_string_to_int(privilege),
            enabled: enabled,
          }
        end

        users
      end

      # Get list of IPMI users for a channel
      def ipmi_user_list(channel)
        output = run_ipmi_command("user list #{channel}")
        ipmi_parse_user_list(output)
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        Chef::Log.warn("Failed to list IPMI users: #{e.message}")
        []
      end

      # Find the slot number for a given username
      def ipmi_find_user_slot(username, channel)
        users = ipmi_user_list(channel)
        user = users.find { |u| u[:username] == username }
        user ? user[:slot] : nil
      end

      # Find the next available slot starting from min_slot
      def ipmi_next_available_slot(channel, min_slot = 3)
        users = ipmi_user_list(channel)

        # Find slots that are empty (no username)
        used_slots = users.select { |u| !u[:username].empty? }.map { |u| u[:slot] }

        # Find first available slot starting from min_slot
        (min_slot..15).each do |slot|
          return slot unless used_slots.include?(slot)
        end

        nil
      end

      # Get the privilege level for a user in a given slot
      def ipmi_user_privilege(slot, channel)
        users = ipmi_user_list(channel)
        user = users.find { |u| u[:slot] == slot }
        user ? user[:privilege] : nil
      end

      # Check if a user in a given slot is enabled
      def ipmi_user_enabled?(slot, channel)
        users = ipmi_user_list(channel)
        user = users.find { |u| u[:slot] == slot }
        user ? user[:enabled] : false
      end

      # Convert privilege string from ipmitool output to integer
      def ipmi_privilege_string_to_int(privilege_str)
        case privilege_str.upcase.strip
        when 'CALLBACK'
          1
        when 'USER'
          2
        when 'OPERATOR'
          3
        when 'ADMINISTRATOR', 'ADMIN'
          4
        when 'OEM PROPRIETARY', 'OEM'
          5
        when 'NO ACCESS', 'UNKNOWN'
          0
        else
          0
        end
      end

      # Convert privilege symbol or integer to integer
      def ipmi_privilege_to_int(privilege)
        case privilege
        when :callback
          1
        when :user
          2
        when :operator
          3
        when :administrator
          4
        when :oem
          5
        when Integer
          privilege
        else
          raise ArgumentError, "Invalid privilege: #{privilege}"
        end
      end

      # Get the current state of an IPMI user
      def ipmi_current_user_state(username, channel)
        slot = ipmi_find_user_slot(username, channel)
        return {} if slot.nil?

        {
          slot: slot,
          privilege: ipmi_user_privilege(slot, channel),
          enabled: ipmi_user_enabled?(slot, channel),
        }
      end

      # Set the username for a slot
      def ipmi_set_username(slot, username)
        run_ipmi_command("user set name #{slot} #{username}")
      end

      # Set the password for a slot
      # Uses -20 flag for passwords > 16 chars (IPMI 2.0 20-byte password support)
      def ipmi_set_password(slot, password)
        if password.length > 16
          run_ipmi_command("user set password #{slot} #{password} 20")
        else
          run_ipmi_command("user set password #{slot} #{password}")
        end
      end

      # Set the privilege level for a slot on a channel
      # Also enables IPMI messaging and link auth for the channel
      def ipmi_set_privilege(slot, privilege, channel)
        run_ipmi_command("channel setaccess #{channel} #{slot} privilege=#{privilege} ipmi=on link=on")
      end

      # Enable a user in a slot (globally and on specific channel)
      def ipmi_enable_user(slot, channel = 1)
        run_ipmi_command("user enable #{slot}")
        run_ipmi_command("channel setaccess #{channel} #{slot} ipmi=on link=on")
      end

      # Disable a user in a slot (globally and on specific channel)
      def ipmi_disable_user(slot, channel = 1)
        run_ipmi_command("channel setaccess #{channel} #{slot} ipmi=off link=off")
        run_ipmi_command("user disable #{slot}")
      end

      # Set enabled status for a slot
      def ipmi_set_enabled(slot, enabled, channel = 1)
        if enabled
          ipmi_enable_user(slot, channel)
        else
          ipmi_disable_user(slot, channel)
        end
      end

      # Clear username from a slot (set to empty string)
      def ipmi_clear_username(slot)
        # ipmitool doesn't support clearing username, so we set to empty
        # Some BMCs may not support this
        run_ipmi_command("user set name #{slot} \"\"")
      rescue Mixlib::ShellOut::ShellCommandFailed
        Chef::Log.warn("Failed to clear username for slot #{slot}, disabling instead")
        run_ipmi_command("user disable #{slot}")
      end

      # Password hash management for idempotency
      IPMI_STATE_DIR = '/var/lib/osl-ipmi'.freeze

      # Calculate a hash of username and password for comparison
      def ipmi_password_hash(username, password)
        require 'digest'
        Digest::SHA256.hexdigest("#{username}:#{password}")
      end

      # Check if password needs to be updated by comparing hashes
      def ipmi_password_needs_update?(username, password)
        hash_file = "#{IPMI_STATE_DIR}/#{username}.pwdhash"
        return true unless ::File.exist?(hash_file)

        current_hash = ::File.read(hash_file).strip
        current_hash != ipmi_password_hash(username, password)
      end

      # Save password hash to state file
      def ipmi_save_password_hash(username, password)
        require 'fileutils'
        ::FileUtils.mkdir_p(IPMI_STATE_DIR, mode: 0700)
        hash_file = "#{IPMI_STATE_DIR}/#{username}.pwdhash"
        ::File.write(hash_file, ipmi_password_hash(username, password))
        ::File.chmod(0600, hash_file)
      end

      # Remove password hash file
      def ipmi_remove_password_hash(username)
        hash_file = "#{IPMI_STATE_DIR}/#{username}.pwdhash"
        ::File.delete(hash_file) if ::File.exist?(hash_file)
      end
    end
  end
end
Chef::DSL::Recipe.include ::OSLResources::Cookbook::Helpers
Chef::Resource.include ::OSLResources::Cookbook::Helpers
# Needed to used in attributes/
Chef::Node.include ::OSLResources::Cookbook::Helpers
