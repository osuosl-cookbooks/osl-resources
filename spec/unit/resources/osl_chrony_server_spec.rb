require_relative '../../spec_helper'

describe 'osl_chrony_server' do
  cached(:subject) { chef_run }
  step_into :osl_chrony_server, :osl_chrony
  platform 'almalinux', '9'
  automatic_attributes['hostname'] = 'ns1'
  automatic_attributes['ipaddress'] = '140.211.166.140'

  recipe do
    osl_chrony_server 'default' do
      ntp_servers(
        'ns1' => %w(140.211.166.140 2605:bc80:3010::140),
        'ns2' => %w(140.211.166.141 2605:bc80:3010::141),
        'ns3' => %w(216.165.191.54 2600:3402:600:24::154)
      )
      allowed_networks %w(140.211.166.0/23 2605:bc80:3010::/48)
      key '746573746b6579746573746b6579746573746b65'
    end
  end

  it { is_expected.to install_package 'chrony' }
  it { is_expected.to enable_service('chrony').with(service_name: 'chronyd') }
  it { is_expected.to disable_service('systemd-timesyncd') }
  [
    /^pool 2\.pool\.ntp\.org iburst maxsources 4$/,
    /^server time\.cloudflare\.com iburst nts$/,
    /^server time\.nist\.gov iburst$/,
    /^peer 140\.211\.166\.141 key 1$/,
    /^peer 2605:bc80:3010::141 key 1$/,
    /^peer 216\.165\.191\.54 key 1$/,
    /^peer 2600:3402:600:24::154 key 1$/,
    %r{^allow 140\.211\.166\.0/23$},
    %r{^allow 2605:bc80:3010::/48$},
    %r{^keyfile /etc/chrony\.keys$},
    /^local stratum 10 orphan$/,
    %r{^driftfile /var/lib/chrony/drift$},
    /^makestep 1\.0 3$/,
    /^rtcsync$/,
    %r{^leapsectz right/UTC$},
    %r{^ntsdumpdir /var/lib/chrony$},
    /^ratelimit interval 1 burst 16$/,
  ].each do |line|
    it { is_expected.to render_file('/etc/chrony.conf').with_content(line) }
  end
  [
    # client-only settings must be gone on a server (a server never syncs to
    # its own service name)
    /^port 0$/,
    /^cmdport 0$/,
    /time\.osuosl\.org/,
    /centos\.pool\.ntp\.org/,
    # never serve the world and never peer with ourselves
    /^allow$/,
    /^allow all$/,
    /^peer 140\.211\.166\.140 /,
    /^peer 2605:bc80:3010::140 /,
    # NTS server bits are inert unless enabled on an off-site node
    /^ntsservercert/,
    /^ntsserverkey/,
  ].each do |line|
    it { is_expected.to_not render_file('/etc/chrony.conf').with_content(line) }
  end
  it do
    is_expected.to create_template('/etc/chrony.keys').with(
      cookbook: 'osl-resources',
      source: 'chrony.keys.erb',
      owner: 'root',
      group: 'chrony',
      mode: '0640',
      sensitive: true
    )
  end
  it do
    is_expected.to render_file('/etc/chrony.keys')
      .with_content(/^1 SHA256 HEX:746573746b6579746573746b6579746573746b65$/)
  end
  it { expect(chef_run.template('/etc/chrony.keys')).to notify('service[chrony]').to(:restart) }

  context 'off-site node (ns3)' do
    cached(:subject) { chef_run }

    automatic_attributes['hostname'] = 'ns3'
    automatic_attributes['ipaddress'] = '216.165.191.54'

    [
      /^peer 140\.211\.166\.140 key 1$/,
      /^peer 2605:bc80:3010::140 key 1$/,
      /^peer 140\.211\.166\.141 key 1$/,
      /^peer 2605:bc80:3010::141 key 1$/,
    ].each do |line|
      it { is_expected.to render_file('/etc/chrony.conf').with_content(line) }
    end
    it { is_expected.to_not render_file('/etc/chrony.conf').with_content(/^peer 216\.165\.191\.54 /) }
    it { is_expected.to_not render_file('/etc/chrony.conf').with_content(/^ntsservercert/) }
  end

  context 'off-site node (ns3) with NTS enabled' do
    cached(:subject) { chef_run }

    automatic_attributes['hostname'] = 'ns3'
    automatic_attributes['ipaddress'] = '216.165.191.54'

    recipe do
      osl_chrony_server 'default' do
        ntp_servers('ns3' => %w(216.165.191.54))
        allowed_networks %w(140.211.166.0/23)
        key '746573746b6579746573746b6579746573746b65'
        enable_nts_server true
        nts_server_cert '/etc/pki/tls/certs/ntp.pem'
        nts_server_key '/etc/pki/tls/private/ntp.key'
      end
    end

    [
      %r{^ntsservercert /etc/pki/tls/certs/ntp\.pem$},
      %r{^ntsserverkey /etc/pki/tls/private/ntp\.key$},
    ].each do |line|
      it { is_expected.to render_file('/etc/chrony.conf').with_content(line) }
    end
  end

  context 'on-site node with NTS enabled by mistake' do
    cached(:subject) { chef_run }

    recipe do
      osl_chrony_server 'default' do
        ntp_servers('ns1' => %w(140.211.166.140))
        allowed_networks %w(140.211.166.0/23)
        key '746573746b6579746573746b6579746573746b65'
        enable_nts_server true
        nts_server_cert '/etc/pki/tls/certs/ntp.pem'
        nts_server_key '/etc/pki/tls/private/ntp.key'
      end
    end

    it { is_expected.to_not render_file('/etc/chrony.conf').with_content(/^ntsservercert/) }
    it { is_expected.to_not render_file('/etc/chrony.conf').with_content(/^ntsserverkey/) }
  end
end
