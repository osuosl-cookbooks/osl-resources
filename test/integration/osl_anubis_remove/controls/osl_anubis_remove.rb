control 'osl_anubis_remove' do
  # The package and the unit template are shared between instances, so a
  # removal has to leave both alone.
  describe package 'anubis' do
    it { should be_installed }
  end

  # The sibling instance is untouched.
  describe service 'anubis@keeper' do
    it { should be_enabled }
    it { should be_running }
  end

  describe port 8933 do
    it { should be_listening }
  end

  %w(/etc/anubis/keeper.env /etc/anubis/botPolicies-keeper.yaml /etc/anubis/keeper.key).each do |f|
    describe file f do
      it { should exist }
    end
  end

  # The removed instance leaves nothing running and no files behind.
  describe service 'anubis@doomed' do
    it { should_not be_enabled }
    it { should_not be_running }
  end

  describe port 8934 do
    it { should_not be_listening }
  end

  %w(/etc/anubis/doomed.env /etc/anubis/botPolicies-doomed.yaml /etc/anubis/doomed.key).each do |f|
    describe file f do
      it { should_not exist }
    end
  end
end
