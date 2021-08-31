release = os.release.to_i
control 'osl_packagecloud_repo' do
  case os.family
  when 'redhat'
    describe yum.repo 'varnishcache_varnish60lts' do
      it { should exist }
      it { should be_enabled }
      if release >= 8
        its('baseurl') { should cmp "https://packagecloud.io/varnishcache/varnish60lts/el/#{release}/x86_64" }
      else
        its('baseurl') { should cmp "https://packagecloud.io/varnishcache/varnish60lts/el/#{release}/x86_64/" }
      end
    end
    describe yum.repo 'varnishcache_varnish40' do
      it { should_not exist }
      it { should_not be_enabled }
    end
  when 'debian'
    describe apt 'https://packagecloud.io/varnishcache/varnish60lts/debian' do
      it { should exist }
      it { should be_enabled }
    end
    describe apt 'https://packagecloud.io/varnishcache/varnish40/debian' do
      it { should_not exist }
      it { should_not be_enabled }
    end
  end
end
