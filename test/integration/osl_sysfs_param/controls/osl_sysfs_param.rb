# This control must pass immediately after a converge AND after a reboot of
# the converged node. Reboot survival comes from three mechanisms working
# together: modules-load.d loads nf_conntrack at boot, the modprobe.d options
# file sets its parameters at load time, and the tmpfiles fragment rewrites
# the built-in ksm tunable.
control 'osl_sysfs_param' do
  describe kernel_module('nf_conntrack') do
    it { should be_loaded }
  end

  # Boot persistence plumbing laid down by the fixture's kernel_module.
  describe file('/etc/modules-load.d/nf_conntrack.conf') do
    it { should exist }
  end

  describe file('/etc/modprobe.d/options_nf_conntrack.conf') do
    its('content') { should eq "options nf_conntrack hashsize=32768 acct=1 tstamp=1\n" }
  end

  # The load-bearing assertions: each runtime parameter actually holds the
  # value the resource was asked to set.
  describe command('cat /sys/module/nf_conntrack/parameters/hashsize') do
    its('exit_status') { should eq 0 }
    its('stdout.strip') { should cmp 32768 }
  end

  # Boolean parameter written in the kernel's normalized readback form.
  describe command('cat /sys/module/nf_conntrack/parameters/acct') do
    its('exit_status') { should eq 0 }
    its('stdout.strip') { should eq 'Y' }
  end

  # Set through param_path with a descriptive resource name.
  describe command('cat /sys/module/nf_conntrack/parameters/tstamp') do
    its('exit_status') { should eq 0 }
    its('stdout.strip') { should eq 'Y' }
  end

  # Non-module sysfs tunable, persisted via tmpfiles.
  describe command('cat /sys/kernel/mm/ksm/run') do
    its('exit_status') { should eq 0 }
    its('stdout.strip') { should cmp 1 }
  end

  # ignore_missing must skip the parameter, not create a regular file in its
  # place.
  describe file('/sys/module/nf_conntrack/parameters/no_such_param') do
    it { should_not exist }
  end

  # persist true lays down a tmpfiles fragment to reapply the value at boot.
  describe file('/etc/tmpfiles.d/chef-sys-kernel-mm-ksm-run.conf') do
    it { should exist }
    its('content') { should eq "w /sys/kernel/mm/ksm/run - - - - 1\n" }
  end

  # The fragment must parse and reapply cleanly, and the value must survive
  # the reapplication. Kept as separate commands: the verifier's sudo
  # prefixes only the first command of a chained string, so anything after
  # && would run unprivileged.
  describe command('systemd-tmpfiles --create /etc/tmpfiles.d/chef-sys-kernel-mm-ksm-run.conf') do
    its('exit_status') { should eq 0 }
  end

  describe command('cat /sys/kernel/mm/ksm/run') do
    its('stdout.strip') { should cmp 1 }
  end

  # persist defaults to false: no fragments for the unpersisted parameters.
  # Module parameters get no fragment at all; their boot story is the
  # modprobe.d options file above.
  describe file('/etc/tmpfiles.d/chef-sys-module-nf_conntrack-parameters-hashsize.conf') do
    it { should_not exist }
  end

  describe file('/etc/tmpfiles.d/chef-sys-module-nf_conntrack-parameters-acct.conf') do
    it { should_not exist }
  end

  describe file('/etc/tmpfiles.d/chef-sys-module-nf_conntrack-parameters-tstamp.conf') do
    it { should_not exist }
  end

  describe file('/etc/tmpfiles.d/chef-sys-module-nf_conntrack-parameters-no_such_param.conf') do
    it { should_not exist }
  end
end
