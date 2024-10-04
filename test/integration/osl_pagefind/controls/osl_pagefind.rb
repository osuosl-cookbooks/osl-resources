control 'osl_pagefind' do
  describe file('/opt/pagefind/pagefind') do
    it { should exist }
    its('size') { should be > 0 }
  end
  describe file('/usr/local/bin/pagefind') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('link_path') { should match %r{/opt/pagefind-1.+/pagefind} }
  end
  describe command '/usr/local/bin/pagefind -V' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /^pagefind 1.+/ }
  end
end
