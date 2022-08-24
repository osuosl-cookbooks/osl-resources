require_relative '../../spec_helper'
require_relative '../../../libraries/helpers'

RSpec.describe OSLResources::Cookbook::Helpers do
  class DummyClass < Chef::Node
    include OSLResources::Cookbook::Helpers
  end

  subject { DummyClass.new }

  describe '#osl_local_ipv4?' do
    it 'local IPv4 address' do
      allow(subject).to receive(:[]).with('ipaddress').and_return('140.211.166.130')
      expect(subject.osl_local_ipv4?).to eq true
    end
    it 'external IPv4 address' do
      allow(subject).to receive(:[]).with('ipaddress').and_return('216.165.191.54')
      expect(subject.osl_local_ipv4?).to eq false
    end
  end

  describe '#osl_local_ipv6?' do
    it 'local IPv6 address' do
      allow(subject).to receive(:[]).with('ip6address').and_return('2605:bc80:3010::130')
      expect(subject.osl_local_ipv6?).to eq true
    end
    it 'external IPv6 address' do
      allow(subject).to receive(:[]).with('ip6address').and_return('2600:3402:600:24::154')
      expect(subject.osl_local_ipv6?).to eq false
    end
  end
end
