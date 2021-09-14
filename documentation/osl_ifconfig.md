# osl_ifconfig

## Actions

- `:create`: Creates an interface (default action)
- `:delete`: Deletes an interface
- `:enable`: Deletes an interface
- `:disable`: Disables an interface

## Properties

Note: All ifcfg options can be found within `/usr/share/doc/initscripts-*/sysconfig.txt`

| Property         | Type          | Default                     | Required  | Description                                                     |
|------------------|---------------|-----------------------------|-----------|-----------------------------------------------------------------|
| `bcast`          | String        |                             |           | ifcfg option (BROADCAST)                                        |
| `bonding_opts`   | String        |                             |           | ifcfg option (BONDING_OPTS)                                     |
| `bootproto`      | String        |                             |           | ifcfg option (BOOTPROTO)                                        |
| `bridge`         | String        |                             |           | ifcfg option (BRIDGE)                                           |
| `defroute`       | String        |                             |           | ifcfg option (DEFROUTE)                                         |
| `delay`          | String        |                             |           | ifcfg option (DELAY)                                            |
| `device`         | String        |                             | :identity | ifcfg option (DEVICE)                                           |
| `ethtool_opts`   | String        |                             |           | ifcfg option (ETHTOOL_OPTS)                                     |
| `force`          | true, false   |                             |           | Force enable or disable action if interface is in desired state |
| `gateway`        | String        |                             |           | ifcfg option (GATEWAY)                                          |
| `hwaddr`         | String        |                             |           | ifcfg option (HWADDR)                                           |
| `ipv6addr`       | String        |                             |           | ifcfg option (IPV6ADDR)                                         |
| `ipv6addrsec`    | Array         |                             |           | ifcfg option (IPV6ADDR_SECONDARIES)                             |
| `ipv6_defaultgw` | String        |                             |           | ifcfg option (IPV6_DEFAULTGW)                                   |
| `ipv6init`       | String        |                             |           | ifcfg option (IPV6INIT)                                         |
| `mask`           | String        |                             |           | ifcfg option (NETMASK)                                          |
| `master`         | String        |                             |           | ifcfg option (MASTER)                                           |
| `metric`         | String        |                             |           | ifcfg option (METRIC)                                           |
| `mtu`            | String        |                             |           | ifcfg option (MTU)                                              |
| `network`        | String        |                             |           | Deprecated: ifcfg option (NETWORK)                              |
| `nm_controlled`  | String        | 'yes' if centos 8 else 'no' |           | ifcfg option (NM_CONTROLLED)                                    |
| `onboot`         | String        | 'yes'                       |           | ifcfg option (ONBOOT)                                           |
| `onparent`       | String        |                             |           | ifcfg option (ONPARENT)                                         |
| `peerdns`        | String        | 'no'                        |           | ifcfg option (PEERDNS)                                          |
| `slave`          | String        |                             |           | ifcfg option (SLAVE)                                            |
| `target`         | String, Array | Resource Name               | yes       | Device to target                                                |
| `type`           | String        |                             |           | ifcfg option (TYPE)                                             |
| `userctl`        | String        |                             |           | ifcfg option (USERCTL)                                          |
| `vlan`           | String        |                             |           | ifcfg option (VLAN)                                             |

## Examples

Simple example:

```ruby
osl_ifconfig 'eth1' do
  target ''
  bootproto 'none'
  nm_controlled 'no'
  device 'eth1'
  type 'dummy'
end
```

Example with ipv6:

```ruby
osl_ifconfig 'eth2' do
  device 'eth2'
  target '172.16.50.10'
  mask '255.255.255.0'
  network '172.16.50.0'
  bootproto 'static'
  onboot 'yes'
  ipv6init 'yes'
  ipv6addr 'fe80::2/64'
  ipv6_defaultgw 'fe80::1/64'
  type 'dummy'
end
```

Multiple target IPs:

```ruby
osl_ifconfig 'eth3' do
  device 'eth3'
  target %w(
    10.1.30.20
    10.1.30.21
  )
  onboot 'yes'
  ipv6init 'yes'
  ipv6addr 'fe80::3/64'
  ipv6addrsec %w(
    fe80::4/64
    fe80::5/64
  )
  ipv6_defaultgw 'fe80::1/64'
  nm_controlled 'yes'
  type 'dummy'
end
```

Enable/disable:

```ruby
osl_ifconfig 'eth4' do
  device 'eth4'
  type 'dummy'
  action [:enable, :disable]
end
```

Delete interface:

```ruby
osl_ifconfig 'eth5' do
  device 'eth5'
  action :delete
end
```

Bond options:

```ruby
osl_ifconfig 'bond0' do
  target '172.16.20.10'
  mask '255.255.255.0'
  network '172.16.20.0'
  device 'bond0'
  bootproto 'static'
  bonding_opts 'mode=0 miimon=100 lacp_rate=0'
  onboot 'yes'
end
```

Bridge interface:

```ruby
osl_ifconfig 'br172' do
  target ''
  device 'br172'
  onboot 'yes'
  bootproto 'none'
  nm_controlled 'no'
  delay '0'
end
```

Use bridge:

```ruby
osl_ifconfig 'eth1vlan172' do
  target ''
  device 'eth1.172'
  onboot 'yes'
  bootproto 'none'
  nm_controlled 'no'
  userctl 'no'
  vlan 'yes'
  bridge 'br172'
end
```
