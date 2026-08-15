# osl_ifconfig

On AlmaLinux 8, this resource uses the network-scripts package in conjunction with ifup/ifdown.
On AlmaLinux 9 and newer, this resource uses nmstate to manage interfaces. The `nmstate`
property overrides that choice if you need to pin one path explicitly.

## Actions

- `:add`: Creates an interface (default action)
- `:delete`: Deletes an interface
- `:enable`: Enables an interface
- `:disable`: Disables an interface

## Address prefixes

Every `ipv4addr` needs a prefix, either from `mask` or written into the address as
`10.1.30.20/24`. A single `mask` covers every address on the interface. An address with no
prefix from either source raises at converge time rather than silently defaulting to `/32`,
which would bring the interface up with no on-link subnet route.

`ipv6addr` and `ipv6addrsec` take their prefix from the address only; `mask` holds IPv4 dotted
netmasks and is not consulted for IPv6. A bare IPv6 address is assumed to be `/64`, matching
how ifcfg-rh has always read `IPV6ADDR=`, and logs a warning. Write the prefix explicitly if
it is anything else — a loopback `::1` wants `/128`.

Gateways (`gateway`, `ipv6_defaultgw`) take a bare address; any prefix written on them is
stripped, since a next hop has no prefix.

## Bringing interfaces up

`:add` is level-triggered. Writing the config notifies an immediate apply, and a second guarded
apply runs whenever the interface is not administratively up, so a host whose config is already
correct but whose interface is down (after a reboot, a failed apply, or an out-of-band
`ip link set down`) is repaired on the next converge rather than reporting a green no-op.

On the ifcfg path the bring-up is `ifup` followed by `ip link set up`: under NetworkManager,
`ifup` on a connection that is already active exits 0 without raising the kernel admin flag,
so it alone cannot repair an active-but-down device.

## Properties

### AlmaLinux 8 (ifcfg)

Note: All ifcfg options can be found within `/usr/share/doc/initscripts-*/sysconfig.txt`

| Property         | Type          | Default       | Description                                                     |
|------------------|---------------|---------------|-----------------------------------------------------------------|
| `bcast`          | String        |               | ifcfg option (BROADCAST)                                        |
| `bonding_opts`   | String        |               | ifcfg option (BONDING_OPTS)                                     |
| `bootproto`      | String        |               | ifcfg option (BOOTPROTO)                                        |
| `bridge`         | String        |               | ifcfg option (BRIDGE)                                           |
| `defroute`       | String        |               | ifcfg option (DEFROUTE)                                         |
| `delay`          | String        |               | ifcfg option (DELAY)                                            |
| `device`         | String        | Name Property | ifcfg option (DEVICE)                                           |
| `ethtool_opts`   | String        |               | ifcfg option (ETHTOOL_OPTS)                                     |
| `force`          | true, false   |               | Force enable or disable action if interface is in desired state |
| `gateway`        | String        |               | ifcfg option (GATEWAY)                                          |
| `hwaddr`         | String        |               | ifcfg option (HWADDR): matches the device's MAC, does not set it |
| `ipv4addr`       | String, Array |               | ifcfg option (IPADDR)                                           |
| `ipv6addrsec`    | Array         |               | ifcfg option (IPV6ADDR_SECONDARIES)                             |
| `ipv6addr`       | String, Array |               | ifcfg option (IPV6ADDR)                                         |
| `ipv6_defaultgw` | String        |               | ifcfg option (IPV6_DEFAULTGW)                                   |
| `ipv6init`       | String        |               | ifcfg option (IPV6INIT)                                         |
| `mask`           | String, Array |               | ifcfg option (NETMASK)                                          |
| `master`         | String        |               | ifcfg option (MASTER)                                           |
| `metric`         | String        |               | ifcfg option (METRIC)                                           |
| `mtu`            | String        |               | ifcfg option (MTU)                                              |
| `network`        | String        |               | Deprecated: ifcfg option (NETWORK)                              |
| `nm_controlled`  | String        | 'yes'         | ifcfg option (NM_CONTROLLED)                                    |
| `onboot`         | String        | 'yes'         | ifcfg option (ONBOOT)                                           |
| `onparent`       | String        |               | ifcfg option (ONPARENT)                                         |
| `peerdns`        | String        | 'no'          | ifcfg option (PEERDNS)                                          |
| `slave`          | String        |               | ifcfg option (SLAVE)                                            |
| `type`           | String        |               | ifcfg option (TYPE)                                             |
| `userctl`        | String        |               | ifcfg option (USERCTL)                                          |
| `vlan`           | String        |               | ifcfg option (VLAN)                                             |

Setting `bonding_opts` also emits `BONDING_MASTER=yes` and infers `TYPE=Bond`, so a bond
master does not have to be named `bondN` to be recognised. Note that `hwaddr` means
different things on the two paths: ifcfg's `HWADDR=` pins the config to the NIC that
already has that MAC (ifup refuses a device whose MAC differs), while nmstate's
`mac-address:` actively sets the MAC on the interface. An `ipv4addr` written as
`10.1.30.20/24` renders as `IPADDR=`/`PREFIX=`; `mask` renders as `NETMASK=`.

### AlmaLinux 9 and newer (nmstate)

Note: Documentation on nmstate can be found at https://nmstate.io/

| Property         | Type          | Default       | Description                                                   |
|------------------|---------------|---------------|---------------------------------------------------------------|
| `bonding_opts`   | String, Array |               | https://nmstate.io/devel/yaml_api.html#bond-interface         |
| `bond_ports`     | String        | `[]`          | https://nmstate.io/devel/yaml_api.html#bond-interface         |
| `bridge`         | String        |               | https://nmstate.io/devel/yaml_api.html#linux-bridge-interface |
| `bridge_ports`   | String        | `[]`          | https://nmstate.io/devel/yaml_api.html#linux-bridge-interface |
| `device`         | String        | Name Property | Ethernet device name                                          |
| `ethtool_opts`   | String        |               | https://nmstate.io/devel/yaml_api.html#ethtool                |
| `gateway`        | String        |               | Default IPv4 gateway IP address                               |
| `hwaddr`         | String        |               | MAC Address                                                   |
| `ipv4addr`       | String, Array | `[]`          | https://nmstate.io/devel/yaml_api.html#ip                     |
| `ipv6addrsec`    | Array         |               | https://nmstate.io/devel/yaml_api.html#ip                     |
| `ipv6addr`       | String, Array |               | https://nmstate.io/devel/yaml_api.html#ip                     |
| `ipv6_autoconf`  | String, Array | `[]`          | https://nmstate.io/devel/yaml_api.html#ip                     |
| `ipv6_defaultgw` | String        |               | https://nmstate.io/devel/yaml_api.html#ip                     |
| `ipv6init`       | String        |               | https://nmstate.io/devel/yaml_api.html#ip                     |
| `mask`           | String, Array | `[]`          | Default IPv4 network mask                                     |
| `mtu`            | String        |               | MTU                                                           |
| `onboot`         | String        | `yes`         | Start interface on boot                                       |
| `type`           | String        |               | https://nmstate.io/devel/yaml_api.html#type                   |
| `vlan`           | String        |               | https://nmstate.io/devel/yaml_api.html#vlan-interface         |
| `bridge_options` | Hash          |               | https://nmstate.io/devel/yaml_api.html#linux-bridge-interface |
| `delay`          | String        |               | ifcfg `DELAY=`: `'0'` turns STP off, 2-30 turns STP on with that forward delay |
| `master`         | String        |               | Controller interface for this port (rendered as `controller:`) |
| `slave`          | String        |               | Accepted for ifcfg parity; membership comes from `master`     |
| `metric`         | String        | `100`         | Metric applied to the default routes this interface installs  |
| `defroute`       | String        |               | `'no'` suppresses the default routes entirely                 |
| `nmstate`        | true, false   | `>= EL9`      | Force the nmstate or the ifcfg path                           |
| `force`          | true, false   | `false`       | Ignore the link-state guard on `:enable`/`:disable`           |

`bridge` and `master` both express member-side membership and render as nmstate's
`controller:` key, matching what `BRIDGE=`/`MASTER=` do on the ifcfg path. You can attach a
port either by naming it in the controller's `bridge_ports`/`bond_ports` or by setting
`bridge`/`master` on the port itself. A bridge named by `bridge` is created on the spot if
it does not exist yet, matching how EL8's `ifup` behaved, so declaration order does not
matter. A bond named by `master` must be declared before its ports, since a bond cannot be
created without its mode.

`ethtool_opts` is only honoured on the ifcfg path; on nmstate it is ignored with a warning.
`bootproto 'dhcp'` is likewise ifcfg-only.

`hwaddr` warns on the nmstate path, because the two paths fail in opposite directions:
ifcfg's `HWADDR=` *matches* (a stale value leaves the interface down), while nmstate
defaults to `identifier: name` and *sets* `mac-address:` (a stale value is pushed onto the
NIC). Use it only when you mean to change the MAC. nmstate's MAC-based interface matching
is a separate feature (`identifier: mac-address`) that this resource does not expose.

Bonding option values are passed through verbatim, so nmstate's named spellings work:
`mode=802.3ad`, `mode=active-backup`, `xmit_hash_policy=layer3+4`, `lacp_rate=fast`.

## Examples

Simple example:

```ruby
osl_ifconfig 'eth1' do
  bootproto 'none'
  type 'dummy'
end
```

Example with ipv6:

```ruby
osl_ifconfig 'eth2' do
  ipv4addr '172.16.50.10'
  mask '255.255.255.0'
  network '172.16.50.0'
  bootproto 'static'
  ipv6init 'yes'
  ipv6addr 'fe80::2/64'
  ipv6_defaultgw 'fe80::1/64'
  type 'dummy'
end
```

Multiple target IPs:

```ruby
osl_ifconfig 'eth3' do
  ipv4addr %w(
    10.1.30.20
    10.1.30.21
  )
  mask '255.255.255.0'
  ipv6init 'yes'
  ipv6addr 'fe80::3/64'
  ipv6addrsec %w(
    fe80::4/64
    fe80::5/64
  )
  ipv6_defaultgw 'fe80::1/64'
  type 'dummy'
end
```

Enable/disable:

```ruby
osl_ifconfig 'eth4' do
  type 'dummy'
  action [:enable, :disable]
end
```

Delete interface:

```ruby
osl_ifconfig 'eth5' do
  action :delete
end
```

Bond options:

```ruby
osl_ifconfig 'bond0' do
  ipv4addr '172.16.20.10'
  mask '255.255.255.0'
  network '172.16.20.0'
  bootproto 'static'
  bonding_opts 'mode=active-backup miimon=100 primary=eth2'
  bond_ports %w(eth2 eth3)
end
```

Bridge interface:

```ruby
osl_ifconfig 'br172' do
  type 'linux-bridge'
  bridge_ports %w(eth1.10)
  bootproto 'none'
end
```

Use VLAN+bridge:

```ruby
osl_ifconfig 'eth1.172' do
  bootproto 'none'
  vlan 'yes'
  bridge 'br172'
end

osl_ifconfig 'br172' do
  type 'linux-bridge'
  bridge_ports %w(eth1.172)
  onboot 'yes'
  bootproto 'none'
end
```
