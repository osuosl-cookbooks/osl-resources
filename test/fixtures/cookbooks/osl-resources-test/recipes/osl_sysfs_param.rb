# nf_conntrack exposes real, writable module parameters in sysfs and is also
# the production use case for this resource, so exercise it directly.
#
# Load the module now and at every boot (modules-load.d), with its parameters
# persisted the canonical way for module params: a modprobe.d options file,
# applied whenever the module loads. The osl_sysfs_param resources below
# cover the running kernel, so a converge takes effect without a reboot or a
# module reload. Do not use persist on module parameters; systemd-tmpfiles
# runs once early in boot and is not ordered after systemd-modules-load, so
# a fragment pointing into /sys/module cannot be relied on. This suite must
# verify green after a reboot, which proves the persistence story end to end.
kernel_module 'nf_conntrack' do
  options [
    'hashsize=32768',
    'acct=1',
    'tstamp=1',
  ]
end

# Integer value, path as the resource name. The kernel rounds hashsize up to
# a multiple of PAGE_SIZE / 8. 32768 is a multiple of that on both 4K and
# 64K page kernels, so the value reads back exactly as written and the
# second converge is a no-op.
osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
  value 32768
end

# Boolean module parameter with normalized readback: the kernel reports Y or
# N regardless of the spelling written, so pass the value in readback form to
# stay idempotent.
osl_sysfs_param '/sys/module/nf_conntrack/parameters/acct' do
  value 'Y'
end

# Descriptive resource name with the path given via param_path.
osl_sysfs_param 'nf_conntrack timestamping' do
  param_path '/sys/module/nf_conntrack/parameters/tstamp'
  value 'Y'
end

# A non-module sysfs tunable: ksm is built into the kernel, so its sysfs
# entries exist before systemd-tmpfiles-setup runs at boot. This is the kind
# of entry persist is for.
osl_sysfs_param '/sys/kernel/mm/ksm/run' do
  value 1
  persist true
end

# A parameter that does not exist is skipped rather than failing the run.
osl_sysfs_param '/sys/module/nf_conntrack/parameters/no_such_param' do
  value 1
  ignore_missing true
end
