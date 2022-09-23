control 'osl_awstats_site' do
  describe directory('/etc/awstats') do
    it { should exist }
  end

  describe file('/etc/awstats/awstats.test.osuosl.org.conf') do
    it { should exist }
    its('content') { should match %r{LogFile=".*/ftp-osl/\*\.log .*/ftp-chi/\*\.log .*/ftp-nyc/\*\.log |"} }
    its('content') { should match /SiteDomain="test\.osuosl\.org"/ }
    its('content') { should match /LogFormat="%virtualname %host %other %logname %time1 %methodurl %code %bytesd %refererquot %uaquot %other"/ }
  end

  describe file('/etc/awstats/awstats.test-full.conf') do
    it { should exist }
    its('content') { should match %r{LogFile=".*/ftp-osl_ftp/\*\.log .*/ftp-chi_ftp/\*\.log .*/ftp-nyc_ftp/\*\.log |"} }
    its('content') { should match /SiteDomain="test-full\.osuosl\.org"/ }
    its('content') { should match /HostAliases="test\.osuosl\.org"/ }
    its('content') { should match /LogFormat="%time3 %other %host %bytesd %url %other %other %method %other %logname %other %code %other %other"/ }
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
    its('content') { should match %r{LogFile=".*/ftp-osl/custom-%YYYY-2%MM-2%DD-2\.log .*/ftp-chi/custom-%YYYY-2%MM-2%DD-2\.log .*/ftp-nyc/custom-%YYYY-2%MM-2%DD-2\.log |"} }
    its('content') { should match /SiteDomain="date-append\.osuosl\.org"/ }
  end
end
