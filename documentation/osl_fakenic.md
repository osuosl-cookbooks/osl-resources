# osl_fakenic

## Actions

- `:create`: Creates a dummy interface (default action)
- `:delete`: Deletes a dummy interface

## Properties

| Property       | Type          | Default         | Required | Description                                          |
|----------------|---------------|-----------------|----------|------------------------------------------------------|
| `interface`    | String        | Resource Name   | yes      | Name for the interface                               |
| `ip4`          | String, Array |                 | yes      | IPv4 address(s) to assign to the interface           |
| `ip6`          | String, Array |                 |          | IPv6 address(s) to assign to the interface           |
| `mac_address`  | String        |                 |          | Mac address to assign to the interface               |
| `multicast`    | true, false   | false           |          | Whether or not to enable multicast for the interface |
| `persist`      | true, false   | true            |          | Recreate the interface at boot via a systemd unit    |

## Examples

Create dummy interface with minimum properties:

```ruby
osl_fakenic 'eth2'
```

Create dummy interface with all properties:

```ruby
osl_fakenic 'eth2' do
  ip4 '192.168.0.1/24'
  ip6 'fe80::1/64'
  mac_address '00:1a:4b:a6:a7:c4'
  multicast true
end
```

Remove dummy interface:

```ruby
osl_fakenic 'eth2' do
  action :delete
end
```

## Surviving a reboot

A dummy interface is runtime-only state, so on its own nothing this resource
creates would survive a reboot. It therefore writes
`/etc/systemd/system/osl-fakenic-<interface>.service` by default: a oneshot
unit ordered `Before=network-pre.target NetworkManager.service` that recreates
the device and the properties this resource owns, then stops.

Set `persist false` to opt out. That also removes a unit an earlier run
created, as does `:delete`, so a deleted interface cannot be resurrected by
the next boot.

```ruby
osl_fakenic 'eth2' do
  ip4 '192.168.0.1/24'
  persist false
end
```

The path to `ip` is resolved at converge time rather than hardcoded, since
systemd needs an absolute path and `ip` is not in the same place on every
platform.

The unit deliberately creates only the *device*. Anything layered on top --
`osl_ifconfig` addressing, bridge or bond membership -- comes back from the
NetworkManager profile or ifcfg file that owns it, which is why the unit runs
before NetworkManager.

Do not set `ip4`/`ip6` here on an interface that `osl_ifconfig` also addresses.
The unit runs first and NetworkManager then reconciles the address list from
its own profile, so the two would fight.
