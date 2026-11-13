require 'chefspec'
require 'chefspec/berkshelf'

ALMA_10 = {
  platform: 'almalinux',
  version: '10',
}.freeze

ALMA_9 = {
  platform: 'almalinux',
  version: '9',
}.freeze

ALMA_8 = {
  platform: 'almalinux',
  version: '8',
}.freeze

ALL_PLATFORMS = [
  ALMA_10,
  ALMA_9,
  ALMA_8,
].freeze

# osl_ifconfig reads the host's saved NetworkManager profiles; no example may read the workstation's own.
RSpec.configure do |config|
  config.before do
    allow_any_instance_of(Chef::Resource).to receive(:osl_nm_saved_profiles).and_return([])
  end
end

shared_context 'sysctl_stubs' do
  before do
    allow_any_instance_of(Chef::Resource).to receive(:shell_out).and_call_original
    allow_any_instance_of(Chef::Resource).to receive(:shell_out)
      .with(/^sysctl -w .*/).and_return(double('Mixlib::ShellOut', error!: false))
    allow_any_instance_of(Chef::Resource).to receive(:shell_out)
      .with(%r{^/bin/systemctl is-enabled .*}).and_return(double('Mixlib::ShellOut', error!: false))
  end
end
