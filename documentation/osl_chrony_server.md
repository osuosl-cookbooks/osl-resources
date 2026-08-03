# osl_chrony_server

Configures chrony as a redundant, symmetric-key-authenticated internal NTP
server (RHEL-only) on top of [`osl_chrony`](osl_chrony.md): external
upstreams, `peer <addr> key <key_id>` lines to every other server in the
cluster, serving restricted to `allowed_networks` (`allow all` is never
emitted).

The key must be the same on every server in the cluster and come from an
encrypted data bag — never an attribute or a committed value.

## Actions

- `:create`: Configures chrony as an NTP server (default).

## Properties

| Property            | Type           | Default                     | Required | Description                                                       |
|---------------------|----------------|-----------------------------|----------|-------------------------------------------------------------------|
| `allowed_networks`  | Array          |                             | yes      | Networks served NTP, one `allow <cidr>` line each                 |
| `conf`              | Hash           | server conf                 | no       | chrony.conf directives (keyfile, orphan stratum, ratelimit, ...)  |
| `enable_nts_server` | `true`/`false` | `false`                     | no       | Serve NTS-KE; only ever takes effect on an off-site server        |
| `key`               | String         |                             | yes      | The shared symmetric key (hex), from an encrypted data bag        |
| `key_id`            | Integer        | `1`                         | no       | Key number used in the keyfile and peer lines                     |
| `ntp_servers`       | Hash           |                             | yes      | Every address of every server, keyed by hostname; a node peers with every address except its own entry |
| `nts_server_cert`   | String         |                             | no       | `ntsservercert` path, rendered only when NTS is active            |
| `nts_server_key`    | String         |                             | no       | `ntsserverkey` path, rendered only when NTS is active             |
| `pools`             | Hash           | `2.pool.ntp.org`            | no       | `pool` directives (`name => options`)                             |
| `servers`           | Hash           | cloudflare (nts) + nist     | no       | `server` directives (`name => options`)                           |

`enable_nts_server` is guarded by `osl_local_ipv4?`: enabling it on an on-site
node stays inert (no NTS directives). Open the firewall separately with
`osl_firewall_ntp` (UDP 123, TCP 4460 via its `nts` property).

## Examples

```ruby
osl_chrony_server 'default' do
  ntp_servers(
    'ns1' => %w(140.211.166.140 2605:bc80:3010::140),
    'ns2' => %w(140.211.166.141 2605:bc80:3010::141),
    'ns3' => %w(216.165.191.54 2600:3402:600:24::154)
  )
  allowed_networks osl_managed_ipv4 + osl_managed_ipv6
  key data_bag_item('chrony', 'keys')['key']
end
```

## Verification

After convergence (allow a few minutes to reach stratum 2-3):

```
chronyc tracking      # stratum 2-3, sane offsets
chronyc sources -v    # upstreams + the peers of the other servers
chronyc serverstats   # NTP packets received counts up
chronyc authdata      # peer links must show the key ID, not "unauthenticated"
chronyc clients       # clients from the allowed networks appear
```
