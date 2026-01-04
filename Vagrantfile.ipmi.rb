# Custom Vagrantfile for IPMI emulation using ipmi_sim
# This file is used by kitchen.libvirt.yml to connect to an external BMC simulator
#
# Prerequisites:
#   1. Start ipmi_sim instances: ./test/fixtures/ipmi_sim/ipmi_sim_control.sh start-all
#   2. Then run kitchen commands
#
# Each suite connects to its own ipmi_sim instance on a unique port
# 192.168.121.1 is the default libvirt NAT network gateway (host IP from guest perspective)

# Port mapping for each suite - order matters! More specific patterns first
IPMI_PORTS = [
  ['osl-ipmi-user-delete', 9121],
  ['osl_ipmi_user_delete', 9121],
  ['osl-ipmi-user-modify', 9131],
  ['osl_ipmi_user_modify', 9131],
  ['osl-ipmi-user', 9111],
  ['osl_ipmi_user', 9111],
].freeze
DEFAULT_PORT = 9101

# Try to determine the suite from the current directory or environment
# Kitchen runs Vagrant from .kitchen/kitchen-vagrant/<instance-name>/
def get_ipmi_port
  # Check current working directory for instance name
  cwd = Dir.pwd
  IPMI_PORTS.each do |suite, port|
    if cwd.include?(suite)
      return port
    end
  end

  # Check environment variable
  instance_name = ENV['KITCHEN_INSTANCE_NAME'] || ''
  IPMI_PORTS.each do |suite, port|
    if instance_name.include?(suite)
      return port
    end
  end

  DEFAULT_PORT
end

Vagrant.configure('2') do |config|
  config.vm.provider :libvirt do |libvirt, _override|
    port = get_ipmi_port

    # Connect to external BMC simulator (ipmi_sim) on the host
    libvirt.qemuargs value: '-chardev'
    libvirt.qemuargs value: "socket,id=ipmi0,host=192.168.121.1,port=#{port},reconnect=10"
    libvirt.qemuargs value: '-device'
    libvirt.qemuargs value: 'ipmi-bmc-extern,id=bmc0,chardev=ipmi0'
    libvirt.qemuargs value: '-device'
    libvirt.qemuargs value: 'isa-ipmi-kcs,bmc=bmc0'
  end
end
