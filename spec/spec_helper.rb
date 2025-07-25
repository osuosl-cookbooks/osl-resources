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

shared_context 'sysctl_stubs' do
  before do
    allow_any_instance_of(Chef::Resource).to receive(:shell_out).and_call_original
    allow_any_instance_of(Chef::Resource).to receive(:shell_out)
      .with(/^sysctl -w .*/).and_return(double('Mixlib::ShellOut', error!: false))
    allow_any_instance_of(Chef::Resource).to receive(:shell_out)
      .with(%r{^/bin/systemctl is-enabled .*}).and_return(double('Mixlib::ShellOut', error!: false))
  end
end
