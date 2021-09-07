# osl_ifconfig

## Actions

- `create`: Creates an interface (default action)
- `delete`: Deletes an interface
- `enable`: Deletes an interface
- `disable`: Deletes an interface

## Properties

| Property         | Type          | Default                     | Required | Description                                                     |
|------------------|---------------|-----------------------------|----------|-----------------------------------------------------------------|
| `bcast`          | String        | None                        | No       | ifcfg option (BROADCAST)                                        |
| `bonding_opts`   | String        | None                        | No       | ifcfg option (BONDING_OPTS)                                     |
| `bootproto`      | String        | None                        | No       | ifcfg option (BOOTPROTO)                                        |
| `bridge`         | String        | None                        | No       | ifcfg option (BRIDGE)                                           |
| `defroute`       | String        | None                        | No       | ifcfg option (DEFROUTE)                                         |
| `delay`          | String        | None                        | No       | ifcfg option (DELAY)                                            |
| `device`         | String        | None                        | identity | ifcfg option (DEVICE)                                           |
| `ethtool_opts`   | String        | None                        | No       | ifcfg option (ETHTOOL_OPTS)                                     |
| `force`          | true, false   | None                        | No       | Force enable or disable action if interface is in desired state |
| `gateway`        | String        | None                        | No       | ifcfg option (GATEWAY)                                          |
| `hwaddr`         | String        | None                        | No       | ifcfg option (HWADDR)                                           |
| `ipv6addr`       | String        | None                        | No       | ifcfg option (IPV6ADDR)                                         |
| `ipv6addrsec`    | Array         | None                        | No       | ifcfg option (IPV6ADDR_SECONDARIES)                             |
| `ipv6_defaultgw` | String        | None                        | No       | ifcfg option (IPV6_DEFAULTGW)                                   |
| `ipv6init`       | String        | None                        | No       | ifcfg option (IPV6INIT)                                         |
| `mask`           | String        | None                        | No       | ifcfg option (NETMASK)                                          |
| `master`         | String        | None                        | No       | ifcfg option (MASTER)                                           |
| `metric`         | String        | None                        | No       | ifcfg option (METRIC)                                           |
| `mtu`            | String        | None                        | No       | ifcfg option (MTU)                                              |
| `network`        | String        | None                        | No       | Deprecated: ifcfg option (NETWORK)                              |
| `nm_controlled`  | String        | 'yes' if centos 8 else 'no' | No       | ifcfg option (NM_CONTROLLED)                                    |
| `onboot`         | String        | 'yes'                       | No       | ifcfg option (ONBOOT)                                           |
| `onparent`       | String        | None                        | No       | ifcfg option (ONPARENT)                                         |
| `peerdns`        | String        | 'no'                        | No       | ifcfg option (PEERDNS)                                          |
| `slave`          | String        | None                        | No       | ifcfg option (SLAVE)                                            |
| `target`         | String, Array | None                        | yes      | Device to target (Name Property)                                |
| `type`           | String        | None                        | No       | ifcfg option (TYPE)                                             |
| `userctl`        | String        | None                        | No       | ifcfg option (USERCTL)                                          |
| `vlan`           | String        | None                        | No       | ifcfg option (VLAN)                                             |

## ifcfg Config Options

| Option               | Definition                                                                                                                                  |
|----------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| BROADCAST            | Broadcast address                                                                                                                           |
| BONDING_OPTS         | Bonding [Options](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-using_channel_bonding) |
| BOOTPROTO            | Boot Protocol: `none`, `bootp`, or `dhcp`                                                                                                   |
| BRIDGE               | Bridge Device: If set the interface will be added to the bridge instead of given an address                                                 |
| DEFROUTE             | Set this interface as default route? (yes, no)                                                                                              |
| DELAY                | Forward delay time (Seconds)                                                                                                                |
| DEVICE               | Name of the physical device                                                                                                                 |
| ETHTOOL_OPTS         | Deprecated: Any device-specefic options that ethtool supports                                                                               |
| GATEWAY              | Gateway IP                                                                                                                                  |
| HWADDR               | Hardware address                                                                                                                            |
| IPV6ADDR             | IPv6 address                                                                                                                                |
| IPV6ADDR_SECONDARIES | List of secondary IPv6 addresses                                                                                                            |
| IPV6_DEFAULTGW       | Adds a default route through the specefied gateway                                                                                          |
| IPV6INIT             | Enable or disable IPv6 static, DHCP, or autoconf configuration for this interface (yes, no)                                                 |
| NETMASK              | Subnet mask                                                                                                                                 |
| MASTER               | Specefies a controller device to bond to                                                                                                    |
| METRIC               | Metric for the default route using `GATEWAY`                                                                                                |
| MTU                  | Default MTU for the device                                                                                                                  |
| NETWORK              | DEPRECATED: Network address (Inferred)                                                                                                      |
| NM_CONTROLLED        | Network Manager can configure? (yes, no)                                                                                                    |
| ONBOOT               | Activated at boot time? (yes, no)                                                                                                           |
| ONPARENT             | Activated when parent is activated? (yes, no)                                                                                               |
| PEERDNS              | Modify /etc/resolv.conf if peer uses msdns extension (PPP only) or DNS{1,2} are set, or if using dhclient? (yes, no)                        |
| SLAVE                | Specefied as running under a controlling device (yes, no)                                                                                   |
| IPADDR               | Used to configure multiple IP addresses `IPADDR<n>=<IP>`                                                                                    |
| TYPE                 | Sets device type (bridge, dummy, etc.)                                                                                                      |
| USERCTL              | Non-root users are allowed to control the device? (yes, no)                                                                                 |
| VLAN                 | Vlan Interface? (yes, no)                                                                                                                   |

## Examples

Simple example

```ruby
osl_ifconfig 'eth1' do
  target ''
  bootproto 'none'
  nm_controlled 'no'
  device 'eth1'
  type 'dummy'
end
```

Example with ipv6

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

Multiple target IPs

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

Enable/disable

```ruby
osl_ifconfig 'eth4' do
  device 'eth4'
  type 'dummy'
  action [:enable, :disable]
end
```

Delete interface

```ruby
osl_ifconfig 'eth5' do
  device 'eth5'
  action :delete
end
```

Bond options

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

Bridge interface

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

Use bridge

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
