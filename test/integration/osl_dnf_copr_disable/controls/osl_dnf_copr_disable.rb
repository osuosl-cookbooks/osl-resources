control 'osl_dnf_copr_disable' do
  describe yum.repo 'copr:copr.fedorainfracloud.org:rapier1:hpnssh' do
    it { should_not exist }
    it { should_not be_enabled }
  end
end
