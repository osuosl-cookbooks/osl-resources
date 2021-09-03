require 'chefspec'
require 'chefspec/berkshelf'

shared_context 'sysctl_stubs' do
  before do
    allow_any_instance_of(Chef::Resource).to receive(:shell_out).and_call_original
    allow_any_instance_of(Chef::Resource).to receive(:shell_out)
      .with(/^sysctl -w .*/).and_return(double('Mixlib::ShellOut', error!: false))
  end
end
