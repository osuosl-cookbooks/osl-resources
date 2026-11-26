require_relative '../../spec_helper'

describe 'osl_cinc_client_updater' do
  step_into :osl_cinc_client_updater

  let(:artifact_version) { '19.4.46' }
  let(:artifact_file) { 'cinc-19.4.46-2.el9.x86_64.rpm' }
  let(:query_status) { false }
  let(:install_status) { false }
  let(:cinc_version) { 'Cinc Client: 19.4.46' }
  let(:installed_release) { '1.el9' }
  let(:backup_exists) { false }

  let(:artifact_json) do
    {
      version: artifact_version,
      url: "https://packages.cinc.sh/files/stable/cinc/#{artifact_version}/el/9/#{artifact_file}",
      install_command: "#!/bin/sh\necho install\n",
    }.to_json
  end

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/opt/cinc.upgrade').and_return(backup_exists)
    allow(File).to receive(:write)
    allow(FileUtils).to receive(:rm_rf)
    allow(FileUtils).to receive(:rm_f)
    allow(FileUtils).to receive(:mv)

    stubs_for_provider('osl_cinc_client_updater[19.4.46]') do |p|
      allow(p).to receive(:osl_cinc_client_post_install)
      allow(p).to receive(:shell_out).with(Gem.ruby, '-e', anything, '19.4.46', 'stable', timeout: 120)
                                     .and_return(double(error?: query_status, stdout: artifact_json, stderr: 'boom'))
      allow(p).to receive(:shell_out).with('rpm', '-q', '--qf', '%{RELEASE}', 'cinc')
                                     .and_return(double(error?: false, stdout: installed_release))
      allow(p).to receive(:shell_out).with('dpkg-query', '-W', '-f=${Version}', 'cinc')
                                     .and_return(double(error?: false, stdout: '19.4.46-1'))
      allow(p).to receive(:shell_out!).with('/bin/sh', %r{/cinc-client-install\.sh\z}, timeout: 600) do
        raise 'install failed' if install_status
      end
      allow(p).to receive(:shell_out!).with('/opt/cinc/bin/cinc-client', '--version')
                                      .and_return(double(stdout: cinc_version))
    end
  end

  shared_examples 'updates' do
    before { chef_run }

    it { is_expected.to install_chef_gem('mixlib-install').with(version: '>= 4.1.2', clear_sources: true, source: 'https://rubygems.cinc.sh') }
    it { expect(FileUtils).to have_received(:mv).with('/opt/cinc', '/opt/cinc.upgrade') }
    it { expect(FileUtils).to_not have_received(:mv).with('/opt/cinc.upgrade', '/opt/cinc') }
    it { expect(File).to have_received(:write).with(%r{/cinc-client-install\.sh\z}, "#!/bin/sh\necho install\n", perm: 0o700) }
  end

  shared_examples 'does not update' do
    before { chef_run }

    it { is_expected.to install_chef_gem('mixlib-install') }
    it { expect(FileUtils).to_not have_received(:mv) }
    it { expect(File).to_not have_received(:write) }
  end

  context 'almalinux, the same version with a newer iteration' do
    platform 'almalinux'
    automatic_attributes['chef_packages'] = { 'chef' => { 'version' => '19.4.46' } }
    recipe do
      osl_cinc_client_updater '19.4.46'
    end

    it_behaves_like 'updates'
  end

  context 'almalinux, an older version' do
    platform 'almalinux'
    automatic_attributes['chef_packages'] = { 'chef' => { 'version' => '18.11.11' } }
    recipe do
      osl_cinc_client_updater '19.4.46'
    end

    it_behaves_like 'updates'
  end

  context 'almalinux, already on the newest iteration' do
    platform 'almalinux'
    automatic_attributes['chef_packages'] = { 'chef' => { 'version' => '19.4.46' } }
    let(:installed_release) { '2.el9' }
    recipe do
      osl_cinc_client_updater '19.4.46'
    end

    it_behaves_like 'does not update'
  end

  context 'almalinux, the installed iteration is unreadable' do
    platform 'almalinux'
    automatic_attributes['chef_packages'] = { 'chef' => { 'version' => '19.4.46' } }
    let(:installed_release) { 'unknown' }
    recipe do
      osl_cinc_client_updater '19.4.46'
    end

    it_behaves_like 'does not update'
  end

  context 'almalinux, a leftover backup after a finished update' do
    platform 'almalinux'
    automatic_attributes['chef_packages'] = { 'chef' => { 'version' => '19.4.46' } }
    let(:installed_release) { '2.el9' }
    let(:backup_exists) { true }
    recipe do
      osl_cinc_client_updater '19.4.46'
    end

    before { chef_run }

    it { expect(FileUtils).to have_received(:rm_rf).with('/opt/cinc.upgrade') }
    it { expect(FileUtils).to_not have_received(:mv) }
  end

  context 'almalinux, the lookup fails' do
    platform 'almalinux'
    automatic_attributes['chef_packages'] = { 'chef' => { 'version' => '18.11.11' } }
    let(:query_status) { true }
    recipe do
      osl_cinc_client_updater '19.4.46'
    end

    it_behaves_like 'does not update'
  end

  context 'almalinux, the install script fails' do
    platform 'almalinux'
    automatic_attributes['chef_packages'] = { 'chef' => { 'version' => '18.11.11' } }
    let(:install_status) { true }
    recipe do
      osl_cinc_client_updater '19.4.46'
    end

    it 'restores the old install and raises' do
      expect { chef_run }.to raise_error(%r{Cinc Client update failed, restored /opt/cinc: install failed})
      expect(FileUtils).to have_received(:mv).with('/opt/cinc.upgrade', '/opt/cinc')
    end
  end

  context 'almalinux, the new version is not installed' do
    platform 'almalinux'
    automatic_attributes['chef_packages'] = { 'chef' => { 'version' => '18.11.11' } }
    let(:cinc_version) { 'Cinc Client: 18.11.11' }
    recipe do
      osl_cinc_client_updater '19.4.46'
    end

    it 'restores the old install and raises' do
      expect { chef_run }.to raise_error(/19\.4\.46 is not the installed version/)
      expect(FileUtils).to have_received(:mv).with('/opt/cinc.upgrade', '/opt/cinc')
    end
  end

  %w(debian ubuntu).each do |p|
    context p do
      platform p
      automatic_attributes['chef_packages'] = { 'chef' => { 'version' => '19.4.46' } }
      let(:artifact_file) { 'cinc_19.4.46-2_amd64.deb' }
      recipe do
        osl_cinc_client_updater '19.4.46'
      end

      it_behaves_like 'updates'
    end
  end

  context 'custom properties' do
    platform 'almalinux'
    automatic_attributes['chef_packages'] = { 'chef' => { 'version' => '18.11.11' } }
    recipe do
      osl_cinc_client_updater 'cinc' do
        version '19.4.46'
        channel 'current'
        rubygems_url 'https://rubygems.example.com'
        install_path '/opt/cinc-test'
        install_timeout 900
        post_install_action 'exec'
      end
    end

    it 'uses them' do
      stubs_for_provider('osl_cinc_client_updater[cinc]') do |p|
        allow(p).to receive(:osl_cinc_client_post_install)
        allow(p).to receive(:shell_out).with(Gem.ruby, '-e', anything, '19.4.46', 'current', timeout: 120)
                                       .and_return(double(error?: false, stdout: artifact_json, stderr: ''))
        allow(p).to receive(:shell_out).with('rpm', '-q', '--qf', '%{RELEASE}', 'cinc')
                                       .and_return(double(error?: false, stdout: '1.el9'))
        allow(p).to receive(:shell_out!).with('/bin/sh', anything, timeout: 900)
        allow(p).to receive(:shell_out!).with('/opt/cinc-test/bin/cinc-client', '--version')
                                        .and_return(double(stdout: cinc_version))
      end
      expect(chef_run).to install_chef_gem('mixlib-install').with(source: 'https://rubygems.example.com')
      expect(FileUtils).to have_received(:mv).with('/opt/cinc-test', '/opt/cinc-test.upgrade')
    end
  end
end
