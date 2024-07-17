os_rel = os.release.to_i

control 'osl_dnsdist' do
  describe package 'dnsdist' do
    it { should be_installed }
  end

  %w(
    dnsdist@auth
    dnsdist@caching
    dnsdist@default
  ).each do |s|
    describe service s do
      it { should be_enabled }
      it { should be_running }
    end
  end

  %w(
    53
    5300
    5301
  ).each do |p|
    describe port p do
      it { should be_listening }
      its('processes') { should include 'dnsdist' }
      its('addresses') { should include '127.0.0.1' }
      its('protocols') { should include 'tcp' }
      its('protocols') { should include 'udp' }
      if p == '53'
        its('addresses') { should include '::1' }
      else
        its('addresses') { should_not include '::1' }
      end
    end
  end

  # test queries
  %w(4 6).each do |ip_ver|
    %w(tcp notcp).each do |opt|
      # default instance
      describe command "dig -#{ip_ver} +#{opt} google.com @localhost" do
        its('exit_status') { should eq 0 }
        its('stdout') { should_not match(/recursion requested but not available/) }
        its('stdout') { should match(/^;; ANSWER SECTION:\ngoogle\.com\./) }
      end
    end
  end

  %w(tcp notcp).each do |opt|
    # caching instance
    describe command "dig -4 +#{opt} google.com @localhost -p 5300" do
      its('exit_status') { should eq 0 }
      its('stdout') { should_not match(/recursion requested but not available/) }
      its('stdout') { should match(/^;; ANSWER SECTION:\ngoogle\.com\./) }
    end

    # auth instance
    describe command "dig -4 +#{opt} google.com @localhost -p 5301" do
      its('exit_status') { should eq 0 }
      its('stdout') { should match(/recursion requested but not available/) }
      its('stdout') { should_not match(/^;; ANSWER SECTION:\ngoogle\.com\./) }
    end

    describe command "dig -4 +#{opt} osuosl.org @localhost -p 5301" do
      its('exit_status') { should eq 0 }
      its('stdout') { should match(/^osuosl\.org\..*300.*IN.*A.*140\.211\.9\.53$/) }
    end
  end

  # metrics
  describe port 8084 do
    it { should be_listening }
    its('processes') { should include 'dnsdist' }
    its('addresses') { should include '0.0.0.0' }
  end

  describe port 8083 do
    it { should be_listening }
    its('processes') { should include 'dnsdist' }
    its('addresses') { should include '127.0.0.1' }
  end

  %w(
    127.0.0.1:8083
    127.0.0.1:8084
  ).each do |host|
    describe http "#{host}/metrics" do
      its('status') { should eq 200 }
      its('body') { should match /^dnsdist_info.*1$/ }
    end

    describe http host do
      its('status') { should eq 401 }
      its('body') { should_not match 'dnsdist' }
    end

    describe http(
      host,
      auth: { user: 'admin', pass: 'password' }
    ) do
      its('status') { should eq 200 }
      its('body') { should match 'dnsdist' }
    end
  end

  describe command "dnsdist -c -C /etc/dnsdist/dnsdist-auth.conf -e 'showServers()'" do
    its('exit_status') { should eq 0 }
    if os_rel >= 9
      its('stdout') { should match /^0\s+140.211.166.140:53\s+up.*auth/ }
      its('stdout') { should match /^1\s+140.211.166.141:53\s+up.*auth/ }
    else
      its('stdout') { should match /^0\s+140.211.166.140:53\s+140.211.166.140:53/ }
      its('stdout') { should match /^1\s+140.211.166.141:53\s+140.211.166.141:53/ }
    end
  end

  describe command "dnsdist -c -C /etc/dnsdist/dnsdist-caching.conf -e 'showServers()'" do
    its('exit_status') { should eq 0 }
    if os_rel >= 9
      its('stdout') { should match /^0\s+140.211.166.130:53\s+up.*caching/ }
      its('stdout') { should match /^1\s+140.211.166.131:53\s+up.*caching/ }
    else
      its('stdout') { should match /^0\s+140.211.166.130:53\s+140.211.166.130:53/ }
      its('stdout') { should match /^1\s+140.211.166.131:53\s+140.211.166.131:53/ }
    end
  end
end
