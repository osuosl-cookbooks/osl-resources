require 'spec_helper'

describe 'osl_route' do
  platform 'almalinux'
  step_into :osl_route

  recipe do
    osl_route 'eth1' do
      routes [
        {
          address: '10.50.0.0',
          netmask: '255.255.254.0',
          gateway: '10.30.0.1',
        },
      ]
    end

    osl_route 'eth2' do
      routes [
        {
          address: '10.60.0.0',
          netmask: '255.255.254.0',
        },
        {
          address: '10.70.0.0',
          netmask: '255.255.254.0',
          gateway: '10.40.0.1',
        },
      ]
    end

    osl_route 'eth3' do
      action :remove
    end
  end

  [
    /^ADDRESS0=10.50.0.0$/,
    /^NETMASK0=255.255.254.0$/,
    /^GATEWAY0=10.30.0.1$/,
  ].each do |line|
    it do
      is_expected.to render_file('/etc/sysconfig/network-scripts/route-eth1').with_content(line)
    end
  end
  [
    /^ADDRESS0=10.60.0.0$/,
    /^NETMASK0=255.255.254.0$/,
    /^ADDRESS1=10.70.0.0$/,
    /^NETMASK1=255.255.254.0$/,
    /^GATEWAY1=10.40.0.1$/,
  ].each do |line|
    it do
      is_expected.to render_file('/etc/sysconfig/network-scripts/route-eth2').with_content(line)
    end
  end
  it do
    is_expected.to_not render_file('/etc/sysconfig/network-scripts/route-eth2').with_content(/^GATEWAY0/)
  end
end
