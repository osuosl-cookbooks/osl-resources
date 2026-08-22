control 'osl_nc_secrets' do
  describe file('/opt/nc-secrets/nc-secrets') do
    it { should exist }
    its('size') { should be > 0 }
  end
  describe file('/usr/local/bin/nc-secrets') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('link_path') { should match %r{/opt/nc-secrets-3.+/nc-secrets} }
  end
  describe command '/usr/local/bin/nc-secrets --help' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match %r{cli for https://apps.nextcloud.com/apps/secrets} }
  end
end
