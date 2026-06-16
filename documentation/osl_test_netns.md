# osl_test_netns

Sets up a `veth` pair with one end inside a dedicated network namespace, so
callers can stand up an isolated, fully bidirectional virtual link for
end-to-end testing of network-listening services on a single host.

Unlike [osl_fakenic](osl_fakenic.md) (a dummy interface, which silently
drops locally-originated broadcasts), this resource gives the test client a
real RX path back to the server, so DHCP OFFERs, ARP replies, and other
locally-originated broadcast traffic actually arrive.

The first end (`server_interface`) is created in the host network namespace
so the service under test binds to it normally. The second end
(`client_interface`) is moved into a separate netns whose name is the
resource name; test clients invoke `ip netns exec <name> ...` to talk to
the server.

## Actions

- `:create`: Creates the netns and veth pair, configures both ends (default action)
- `:delete`: Removes the veth pair and the netns

## Properties

| Property            | Type   | Default                         | Required | Description                                                        |
|---------------------|--------|---------------------------------|----------|--------------------------------------------------------------------|
| `netns_name`        | String | Resource Name                   | yes      | Name of the network namespace                                      |
| `server_interface`  | String | `veth-srv-#{netns_name[0, 6]}`  |          | Name of the host-side veth peer (max 15 chars per IFNAMSIZ)        |
| `server_ip`         | String |                                 | yes      | IPv4 address (CIDR) assigned to the server-side interface          |
| `client_interface`  | String | `veth-cli-#{netns_name[0, 6]}`  |          | Name of the netns-side veth peer (max 15 chars per IFNAMSIZ)       |
| `client_ip`         | String |                                 | yes      | IPv4 address (CIDR) assigned to the client-side interface          |
| `client_mac`        | String |                                 |          | MAC address to set on the client-side interface (e.g. for DHCP reservations) |

## Examples

Create a test netns with explicit interface names and a fixed client MAC:

```ruby
osl_test_netns 'testclient' do
  server_interface 'veth-srv'
  server_ip        '140.211.166.158/28'
  client_interface 'veth-cli'
  client_ip        '140.211.166.157/28'
  client_mac       '00:1a:4b:a6:a7:c4'
end
```

Remove the netns and veth pair:

```ruby
osl_test_netns 'testclient' do
  action :delete
end
```

## Using the netns from InSpec or scripts

```bash
# Run a command inside the netns:
ip netns exec testclient ping -c1 140.211.166.158

# Send a DHCPDISCOVER via the client interface:
sudo ip netns exec testclient /usr/local/bin/dhcp4-probe.py --iface veth-cli
```

## Notes

- veth is in the upstream kernel without a separate module load, so no
  `kernel_module` resource is needed (unlike `osl_fakenic`'s `dummy` load).
- Inside containers (dokken), `ip netns` needs `CAP_SYS_ADMIN` and a
  writable `/var/run/netns`. The repo's `kitchen.dokken.yml` runs with
  `privileged: true`, which provides both.
