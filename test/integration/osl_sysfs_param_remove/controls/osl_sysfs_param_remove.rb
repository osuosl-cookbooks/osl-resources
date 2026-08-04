control 'osl_sysfs_param_remove' do
  # The runtime value must still be applied.
  describe command('cat /sys/module/nf_conntrack/parameters/hashsize') do
    its('exit_status') { should eq 0 }
    its('stdout.strip') { should cmp 32768 }
  end

  # The stale fragment seeded before the resource ran must be gone.
  describe file('/etc/tmpfiles.d/chef-sys-module-nf_conntrack-parameters-hashsize.conf') do
    it { should_not exist }
  end
end
