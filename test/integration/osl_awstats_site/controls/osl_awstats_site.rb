control 'osl_awstats_site' do
  describe directory('/etc/awstats') do
    it { should exist }
  end

  describe file('/etc/awstats/awstats.test.osuosl.org.conf') do
    it { should exist }
    its('content') { should match %r{ftp-osl\/\*\.log} }
    its('content') { should match %r{ftp-nyc\/\*\.log} }
    its('content') { should match %r{ftp-chi\/\*\.log} }
    its('content') { should match /SiteDomain="test\.osuosl\.org"/ }
  end

  describe file('/etc/awstats/awstats.test-full.conf') do
    it { should exist }
    its('content') { should match /ftp-osl_ftp/ }
    its('content') { should match /ftp-nyc_ftp/ }
    its('content') { should match /ftp-chi_ftp/ }
    its('content') { should match /SiteDomain="test-full\.osuosl\.org"/ }
    its('content') { should match /HostAliases="test\.osuosl\.org"/ }
    its('content') { should match /optionA=true/ }
    its('content') { should match /optionB=50/ }
  end

  describe file('/etc/awstats/awstats.non-osl-mirror.example.com.conf') do
    it { should exist }
    its('content') { should match /LogFile="external-mirror\.log"/ }
    its('content') { should match /SiteDomain="non-osl-mirror\.example\.com"/ }
  end

  describe file('/etc/awstats/awstats.date-append.osuosl.org.conf') do
    it { should exist }
    its('content') { should match /custom-%YYYY-2%MM-2%DD-2\.log/ }
  end
end
