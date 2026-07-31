# osl_chrony

Installs and configures chrony as the system NTP client, disabling ntpd and
systemd-timesyncd. Also the rendering engine used by
[`osl_chrony_server`](osl_chrony_server.md).

## Actions

- `:create`: Installs chrony and renders chrony.conf (default).

## Properties

| Property           | Type    | Default                    | Required | Description                                                        |
|--------------------|---------|----------------------------|----------|--------------------------------------------------------------------|
| `allowed_networks` | Array   | `[]`                       | no       | Networks served NTP, one `allow <cidr>` line each                  |
| `conf`             | Hash    | client conf (serving off)  | no       | chrony.conf directives (`nil` value renders a bare directive)      |
| `key`              | String  |                            | no       | Symmetric key (hex); renders the keyfile and a `keyfile` directive |
| `key_id`           | Integer | `1`                        | no       | Key number used in the keyfile and `peer ... key N` lines          |
| `keyfile`          | String  | `/etc/chrony.keys`         | no       | Path of the rendered keyfile (RHEL-only)                           |
| `nts_server_cert`  | String  |                            | no       | Renders `ntsservercert` when set together with `nts_server_key`    |
| `nts_server_key`   | String  |                            | no       | Renders `ntsserverkey` when set together with `nts_server_cert`    |
| `peers`            | Array   | `[]`                       | no       | Peer addresses, one `peer <addr> key <key_id>` line each           |
| `pools`            | Hash    | OSL + external fallback    | no       | `pool` directives (`name => options`)                              |
| `servers`          | Hash    | `{}`                       | no       | `server` directives (`name => options`)                            |

The default `pools` uses `time.osuosl.org` (a DNS round-robin over the
internal NTP servers) with `iburst maxsources 3`, so chrony tracks all of its
addresses and replaces any that become unreachable, plus `2.pool.ntp.org`
(`iburst maxsources 2`) as an external fallback. The default `conf` disables
serving (`port 0` / `cmdport 0`).

## Examples

The fleet-wide NTP client:

```ruby
osl_chrony 'default'
```
