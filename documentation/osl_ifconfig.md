# osl_ifconfig

On AlmaLinux 8, this resource uses the network-scripts package in conjunction with ifup/ifdown.
On AlmaLinux 9, this resource uses nmstate to manage interfaces

## Actions

- `:create`: Creates an interface (default action)
- `:delete`: Deletes an interface
- `:enable`: Enables an interface
- `:disable`: Disables an interface

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
| `hwaddr`         | String        |               | ifcfg option (HWADDR)                                           |
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

### AlmaLinux 9 (nmstate)

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
  bonding_opts 'mode=0 miimon=100 lacp_rate=0'
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
