require 'chefspec'
require 'chefspec/berkshelf'

CENTOS_8 = {
  platform: 'centos',
  version: '8',
}.freeze

CENTOS_7 = {
  platform: 'centos',
  version: '7',
}.freeze

DEBIAN_10 = {
  platform: 'debian',
  version: '10',
}.freeze

ALL_PLATFORMS = [
  CENTOS_8,
  CENTOS_7,
  DEBIAN_10,
].freeze

ALL_DEBIAN = [
  DEBIAN_10,
].freeze

ALL_RHEL = [
  CENTOS_8,
  CENTOS_7,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end

shared_context 'sysctl_stubs' do
  before do
    allow_any_instance_of(Chef::Resource).to receive(:shell_out).and_call_original
    allow_any_instance_of(Chef::Resource).to receive(:shell_out)
      .with(/^sysctl -w .*/).and_return(double('Mixlib::ShellOut', error!: false))
  end
end
