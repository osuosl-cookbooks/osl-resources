control 'osl_hugo' do
  describe file('/opt/hugo/hugo') do
    it { should exist }
    its('size') { should be > 0 }
  end
  describe file('/usr/local/bin/hugo') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('link_path') { should match %r{/opt/hugo-0.+/hugo} }
  end
  describe command '/usr/local/bin/hugo version' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /^hugo v0.+/ }
  end
end
