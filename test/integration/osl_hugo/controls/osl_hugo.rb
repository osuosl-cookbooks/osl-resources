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
    its('stdout') { should match /^hugo v0\.\d+\.\d+/ }
  end
end

# Absolute paths throughout: sudo's secure_path on AlmaLinux leaves out /usr/local/bin
control 'osl_hugo_dart_sass' do
  describe file('/usr/local/bin/sass') do
    it { should be_symlink }
    its('link_path') { should match %r{/opt/dart-sass-1.+/sass} }
  end
  describe command '/usr/local/bin/sass --version' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /^1\.\d+\.\d+/ }
  end
  describe command %q(sh -c "echo 'a { b: c }' | /usr/local/bin/sass --stdin") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /b: c;/ }
  end
  describe command 'env PATH=/usr/local/bin:/usr/bin:/bin /usr/local/bin/hugo env' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match %r{github.com/sass/dart-sass/compiler="1\.} }
  end
end
