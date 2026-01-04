# osl_ipmi_user

Manages IPMI users on physical nodes using `ipmitool`.

This resource provides a safe, idempotent way to create, modify, and delete
IPMI/BMC users. It will soft-fail on systems without IPMI hardware, making it
safe to include in recipes that run on both physical and virtual machines.

## Requirements

- Physical hardware with IPMI/BMC support
- IPMI device available at `/dev/ipmi0`, `/dev/ipmi/0`, or `/dev/ipmidev/0`
- The `ipmitool` package (automatically installed by this resource)

## Actions

| Action    | Description                                                                                     |
| --------- | ----------------------------------------------------------------------------------------------- |
| `:create` | **(Default)** Create a new IPMI user or update privilege/enabled status of existing user. Password only set on create.  |
| `:delete` | Disable and remove an existing IPMI user. Protected slots (below `min_slot`) cannot be deleted. |
| `:modify` | Update an existing user's privilege, password, or enabled                                       |
|           | status. Will warn if user doesn't exist.                                                        |

## Properties

| Property    | Type              | Default       | Required           | Description                           |
| ----------- | ----------------- | ------------- | ------------------ | ------------------------------------- |
| `username`  | String            | name property | Yes                | The IPMI username. Max 16 characters. |
| `password`  | String            | -             | Yes (for :create)  | The user password. Max 20 characters. |
| `privilege` | Integer or Symbol | -             | Yes (for :create)  | Privilege level.                      |
| `channel`   | Integer           | `1`           | No                 | IPMI LAN channel.                     |
| `enabled`   | Boolean           | `true`        | No                 | Account enabled?                      |
| `min_slot`  | Integer           | `3`           | No                 | Minimum slot for new users.           |

> **Note:** IPMI 1.5 supports passwords up to 16 characters. IPMI 2.0 extends
> this to 20 characters. Passwords longer than 16 characters automatically use
> IPMI 2.0 mode. Ensure your BMC supports IPMI 2.0 if using passwords longer
> than 16 characters.

### Privilege Levels

The `privilege` property accepts either an integer (1-5) or a symbol:

| Symbol           | Integer | Description                        |
| ---------------- | ------- | ---------------------------------- |
| `:callback`      | 1       | Callback access only               |
| `:user`          | 2       | User-level access (read-only)      |
| `:operator`      | 3       | Operator-level access (some ctrl)  |
| `:administrator` | 4       | Full administrative access         |
| `:oem`           | 5       | OEM-defined proprietary access     |

## Behavior Notes

### Soft-Fail on Non-IPMI Systems

If no IPMI device is detected, the resource logs a warning and skips execution
without failing the Chef run. This allows the resource to be safely included
in recipes that run on both physical and virtual machines.

### Slot Management

IPMI user databases have a limited number of slots (typically 10-15). This
resource:

- Protects slots 1-2 by default (configurable via `min_slot`)
- Automatically finds the next available slot for new users
- Warns if no slots are available

### Password Handling

- Passwords are set when a new user is created or when explicitly modified
- After setting, a SHA256 hash is stored in `/var/lib/osl-ipmi/<user>.pwdhash`
- On subsequent runs, the resource compares the hash to check for changes
- This provides idempotency despite IPMI not supporting password readback
- Passwords are marked as sensitive and will not appear in Chef logs

> **Note:** If the hash file is deleted or missing, the password will be set
> again on the next Chef run. This is by design to ensure passwords can be
> reset when needed.

### Idempotency

The resource is idempotent for:

- User existence checking
- Privilege level comparison
- Enabled status comparison
- Password management (via hash file tracking)

The password hash is stored in `/var/lib/osl-ipmi/` with mode 0600 for security.
When a user is deleted, the corresponding hash file is also removed.

## Examples

### Create an administrator user

```ruby
osl_ipmi_user 'admin' do
  password 'SecurePassword123!'
  privilege :administrator
end
```

### Create an operator user on a specific channel

```ruby
osl_ipmi_user 'monitoring' do
  password 'MonitorPass456!'
  privilege :operator
  channel 2
end
```

### Create a disabled user

```ruby
osl_ipmi_user 'backup_admin' do
  password 'BackupPass789!'
  privilege :administrator
  enabled false
end
```

### Delete a user

```ruby
osl_ipmi_user 'olduser' do
  action :delete
end
```

### Modify an existing user's password

```ruby
osl_ipmi_user 'admin' do
  password 'NewSecurePassword!'
  privilege :administrator
  action :modify
end
```

### Using with encrypted data bags (wrapper recipe pattern)

```ruby
# In your wrapper cookbook/recipe:
ipmi_secrets = data_bag_item('secrets', 'ipmi')

osl_ipmi_user 'admin' do
  password ipmi_secrets['admin_password']
  privilege :administrator
end

osl_ipmi_user 'operator' do
  password ipmi_secrets['operator_password']
  privilege :operator
end
```

### Using privilege as integer

```ruby
osl_ipmi_user 'admin' do
  password 'SecurePassword123!'
  privilege 4  # Administrator
end
```

### Custom min_slot for protected slots

By default, slots 1-2 are protected. You can adjust this:

```ruby
# Protect slots 1-4 (only allow new users in slots 5+)
osl_ipmi_user 'newuser' do
  password 'Password123!'
  privilege :operator
  min_slot 5
end
```

### Change user privilege level

```ruby
# First create the user
osl_ipmi_user 'operator' do
  password 'OperatorPass!'
  privilege :operator
end

# Later, promote to administrator
osl_ipmi_user 'operator' do
  privilege :administrator
  action :modify
end
```

### Disable a user without deleting

```ruby
osl_ipmi_user 'tempuser' do
  enabled false
  action :modify
end
```

### Re-enable a disabled user

```ruby
osl_ipmi_user 'tempuser' do
  enabled true
  action :modify
end
```

## Troubleshooting

### "No IPMI device found, skipping"

This warning indicates the system doesn't have IPMI hardware or the IPMI kernel
modules aren't loaded. This is expected on virtual machines.

To load IPMI modules manually:

```bash
modprobe ipmi_devintf
modprobe ipmi_si
```

### "No available IPMI user slots"

The IPMI user database is full. Delete unused users or increase the available
slots if your BMC firmware supports it.

### "Cannot delete user in protected slot"

Users in slots below `min_slot` (default: 3) are protected from deletion. This
prevents accidentally removing critical system users. If you need to delete a
user in a protected slot, either:

- Lower the `min_slot` value (not recommended)
- Manually delete the user using `ipmitool user set name <slot> ""` directly

### User not being created in expected slot

New users are created in the first available slot starting from `min_slot`.
If you need a user in a specific slot, ensure previous slots are either empty
or contain named users.

### Modify action shows "User does not exist, cannot modify"

The `:modify` action requires the user to already exist. Use `:create` first
to create the user, then `:modify` to update specific attributes.

## Testing

### Unit Tests

```bash
rspec spec/unit/resources/osl_ipmi_user_spec.rb
rspec spec/unit/libraries/helpers_spec.rb
```

### Integration Tests with IPMI Emulation

Integration tests run on VMs using QEMU/KVM with OpenIPMI's `ipmi_sim`
BMC emulation.

#### Prerequisites

1. **Linux host with KVM/QEMU and libvirt**:

   ```bash
   sudo dnf install -y qemu-kvm libvirt virt-install libvirt-devel OpenIPMI
   sudo systemctl enable --now libvirtd
   ```

2. **Vagrant with libvirt plugin**:

   ```bash
   vagrant plugin install vagrant-libvirt
   ```

#### Running Tests

```bash
# Run a specific test suite (ipmi_sim auto-managed via lifecycle hooks)
KITCHEN_YAML=kitchen.libvirt.yml kitchen test osl-ipmi-user-almalinux-9

# Or step-by-step for debugging:
KITCHEN_YAML=kitchen.libvirt.yml kitchen converge osl-ipmi-user-almalinux-9
KITCHEN_YAML=kitchen.libvirt.yml kitchen verify osl-ipmi-user-almalinux-9
KITCHEN_YAML=kitchen.libvirt.yml kitchen destroy osl-ipmi-user-almalinux-9
```

#### Available Test Suites

| Suite                | Description                                         |
| -------------------- | --------------------------------------------------- |
| `osl-ipmi-user`      | Tests user creation (idempotent, runs twice)        |
| `osl-ipmi-user-del`  | Tests user deletion                                 |
| `osl-ipmi-user-mod`  | Tests modify action (privilege, password, enabled)  |

#### Manual ipmi_sim Control

```bash
# Start/stop/reset instances manually
./test/fixtures/ipmi_sim/ipmi_sim_control.sh start osl-ipmi-user
./test/fixtures/ipmi_sim/ipmi_sim_control.sh reset osl-ipmi-user # Clear state and restart
./test/fixtures/ipmi_sim/ipmi_sim_control.sh stop osl-ipmi-user
./test/fixtures/ipmi_sim/ipmi_sim_control.sh status-all
```

### Physical Machine Testing

For testing on real IPMI hardware:

```bash
KITCHEN_YAML=kitchen.exec.yml kitchen test osl-ipmi-user-local
```

### Manual Verification

```bash
# List all IPMI users
sudo ipmitool user list 1

# Test user authentication (if LAN configured)
ipmitool -I lanplus -H <bmc-ip> -U <username> -P <password> user list 1
```

## See Also

- `ipmitool(1)` man page
- IPMI 2.0 Specification
- [OpenIPMI documentation](https://openipmi.sourceforge.io/)
