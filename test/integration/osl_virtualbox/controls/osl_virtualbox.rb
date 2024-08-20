vagrant = inspec.file('/home/vagrant').exist?

control 'osl_virtualbox' do
  describe command 'vboxmanage list hostinfo' do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /Processor supports HW virtualization: yes/ } unless vagrant
  end

  %w(kvm_amd kvm_intel kvm).each do |m|
    describe kernel_module m do
      it { should_not be_loaded }
      it { should be_blacklisted }
    end
  end

  describe kernel_module 'vboxdrv' do
    it { should be_loaded }
  end
end
