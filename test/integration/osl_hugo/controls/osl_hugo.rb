control 'osl_hugo' do
  describe directory('/opt/hugo-0.120.4') do
    it { should exist }
  end
  describe directory('/opt/hugo') do
    it { should exist }
    its('link_path') { should cmp '/opt/hugo-0.120.4' }
  end
  describe file('/usr/local/bin/hugo') do
    it { should exist }
    its('mode') { should cmp '0755' }
  end
  describe command 'hugo help' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /Usage:/ }
  end
end
