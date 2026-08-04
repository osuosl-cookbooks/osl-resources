kernel_module 'nf_conntrack' do
  action :load
end

# Simulate a fragment left behind by an earlier run with persist true.
file '/etc/tmpfiles.d/chef-sys-module-nf_conntrack-parameters-hashsize.conf' do
  content "w /sys/module/nf_conntrack/parameters/hashsize - - - - 32768\n"
  mode '0644'
end

# persist defaults to false, which must clean up the stale fragment while
# still applying the runtime value.
osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
  value 32768
end
