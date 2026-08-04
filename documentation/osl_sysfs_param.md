# osl_sysfs_param

Sets a runtime kernel parameter exposed through `sysfs` (or any other
pseudo-filesystem entry, such as one under `/proc`) idempotently, so recipes
do not have to fall back to `execute` with a raw `echo` redirect.

Use this for parameters that `sysctl` does not cover. Module parameters under
`/sys/module/<module>/parameters/` are the common case: they are writable at
runtime but have no `sysctl` key, so the only way to change them on a running
system is to write the file directly. Pair it with a `/etc/modprobe.d` entry
when the value also needs to survive a reboot.

## Actions

- `:set`: Writes the value if it differs from what the parameter currently reads (default action)

## Properties

| Property         | Type              | Default       | Required | Description                                                                 |
|------------------|-------------------|---------------|----------|-----------------------------------------------------------------------------|
| `param_path`     | String            | Resource Name | yes      | Full path to the sysfs entry to write                                       |
| `value`          | String, Integer   |               | yes      | Value to write; coerced to a stripped String                                |
| `ignore_missing` | true, false       | `false`       |          | Skip with a warning instead of failing when `param_path` does not exist     |
| `persist`        | true, false       | `false`       |          | Also write a systemd-tmpfiles fragment so the value is reapplied at boot    |

## Examples

Set the `nf_conntrack` hash table size on a running host:

```ruby
osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
  value 524288
end
```

Use `param_path` explicitly when a more descriptive resource name is wanted:

```ruby
osl_sysfs_param 'nf_conntrack hashsize' do
  param_path '/sys/module/nf_conntrack/parameters/hashsize'
  value      node['osl-openstack']['conntrack']['hashsize']
end
```

Tolerate a parameter that may not be present, for example when the module
providing it is not loaded on every host in a role:

```ruby
osl_sysfs_param '/sys/module/nf_conntrack/parameters/hashsize' do
  value 524288
  ignore_missing true
end
```

Set a value now and have it reapplied at boot via systemd-tmpfiles:

```ruby
osl_sysfs_param '/sys/kernel/mm/ksm/run' do
  value 1
  persist true
end
```

## Persistence across reboots

`osl_sysfs_param` on its own only changes the running kernel. Pick the
persistence mechanism by the kind of entry being written:

- Module parameters (`/sys/module/<mod>/parameters/*`): use an
  `/etc/modprobe.d/<mod>.conf` `options` line alongside this resource, as
  `osl-openstack::compute` does for `nf_conntrack`. Do not use `persist` for
  these; see the caveat below.
- `/proc/sys/*`: use Chef's `sysctl` resource instead of this one. It applies
  the value at runtime and writes `/etc/sysctl.d` in one step.
- Everything else (`/sys/kernel/mm/*`, `/sys/block/*/queue/*`, and similar):
  set `persist true`. The resource writes a one-line fragment to
  `/etc/tmpfiles.d/chef-<param-path>.conf` and `systemd-tmpfiles-setup`
  reapplies the value at every boot.

Caveats of `persist`:

- `systemd-tmpfiles-setup.service` runs once, early in boot. A `w` line is
  silently skipped when its path does not exist yet (same semantics as
  `ignore_missing`), so `persist` only works for entries present at that
  point: built-in kernel tunables and devices enumerated before it runs.
- A module loaded later in boot gets its sysfs parameters after tmpfiles has
  already run, so nothing is applied. This holds even for modules listed in
  `/etc/modules-load.d`: systemd-tmpfiles-setup is not ordered after
  systemd-modules-load, so there is no guarantee the parameter path exists
  when the fragment is processed. Module parameters belong in
  `/etc/modprobe.d`, which kmod evaluates at load time wherever that happens.
  The `kernel_module` resource's `options` property manages exactly that file
  and its default `:install` action persists the module load itself; pair it
  with this resource as `osl-openstack::compute` does, or see the
  `osl_sysfs_param` kitchen suite for a complete reboot-tested example.
- For attributes of hotplug devices, use a udev rule (see
  [osl_udev_rules](osl_udev_rules.md)) so the write fires when the device
  appears. systemd path units are not an option here; sysfs does not generate
  the inotify events they rely on.
- `persist false` (the default) deletes the fragment this resource would have
  created, so turning `persist` off later cleans up after itself.
- The fragment is only read at boot. During a Chef run the resource itself
  applies the runtime value, so `systemd-tmpfiles --create` is not invoked.

## Notes

- The current value is compared with trailing whitespace stripped from both
  sides, so parameters that read back without a trailing newline still
  converge exactly once.
- The read and write go through native Ruby `File` methods in
  `libraries/helpers.rb` rather than a `file` resource. sysfs entries are not
  regular files, and the `file` provider's content staging, backup and atomic
  rename steps do not work reliably against them. The write is wrapped in
  `converge_by`, so why-run and the updated-resource count still report
  correctly.
- By default a missing `param_path` raises `Chef::Exceptions::FileNotFound`
  with a message pointing at the likely cause, which is the providing module
  not being loaded. Set `ignore_missing true` to downgrade that to a warning.
- There is no delete or reset action. sysfs entries cannot be removed, and the
  kernel does not expose a parameter's boot-time default, so there is nothing
  to reset to. Reboot the host or reload the module to get defaults back.
- Some parameters normalize what they report, for example returning `Y` for a
  boolean written as `1`, or bracketing the active choice like
  `/sys/kernel/mm/transparent_hugepage/defrag` returning `always [defer] ...`.
  Those converge on every run. Pass the value in the form the parameter reads
  back where possible to keep the resource idempotent.
- This only changes the running kernel unless `persist` is set. See
  "Persistence across reboots" above for choosing between `persist`,
  `/etc/modprobe.d`, and the `sysctl` resource.
