control 'osl_hugo' do
  describe file('/opt/hugo/hugo') do
    it { should exist }
    its('size') { should be > 0 }
  end
  describe file('/usr/local/bin/hugo') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('link_path') { should cmp '/opt/hugo-0.120.4/hugo' }
  end
  describe command '/usr/local/bin/hugo version' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /0.120.4/ }
  end
end
