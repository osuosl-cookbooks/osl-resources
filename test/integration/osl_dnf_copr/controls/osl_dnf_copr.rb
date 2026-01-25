control 'osl_dnf_copr' do
  describe yum.repo 'copr:copr.fedorainfracloud.org:rapier1:hpnssh' do
    it { should exist }
    it { should be_enabled }
  end
end
