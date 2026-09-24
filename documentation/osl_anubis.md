# osl_anubis

Configures an instance of [Anubis](https://anubis.techaro.lol), the proof-of-work
scraper defense proxy, from the `anubis` package in the OSL yum repo (RHEL-only).

Each resource name maps to one instance of the packaged `anubis@.service`
systemd template, so a single host can run several instances side by side. The
resource writes two files per instance: `/etc/anubis/<name>.env` for the
process settings and `/etc/anubis/botPolicies-<name>.yaml` for the bot rules.
Both notify a restart.

Anubis is meant to sit behind a reverse proxy. The proxy **must** set
`X-Real-IP` (or an `X-Forwarded-For` containing only the real client address) —
without it anubis rejects every request with
`[misconfiguration] X-Real-Ip header is not set`.

## Actions

- `:create`: Installs anubis and configures the instance (default)
- `:restart`: Restarts the instance's service
- `:remove`: Stops and disables the instance's service and deletes its env,
  policy and key files. The `anubis` package is left installed, since the unit
  is a template and other instances on the host may still need it. The metrics
  firewall port also stays open -- `osl_firewall_port` has no removal action --
  but it is `osl_only` and nothing listens on it once the service is stopped.
  When no other instance's env file is left on the host, the shared
  `valkey@anubis` is stopped and disabled too (its data directory and SELinux
  port label stay).

## Properties

| Property                  | Type           | Default                            | Required | Description                                                                     |
|---------------------------|----------------|------------------------------------|----------|---------------------------------------------------------------------------------|
| `bind`                    | String         | `127.0.0.1:8932`                   | no       | Address anubis listens on; give each instance its own port                       |
| `bind_network`            | String         | `tcp`                              | no       | Address family (`tcp` or `unix`)                                                 |
| `cookie_domain`           | String         |                                    | no       | Top-level domain the challenge cookie is valid for                               |
| `cookie_expiration_time`  | String         | `168h`                             | no       | How long a passed challenge stays valid                                          |
| `cookie_partitioned`      | `true`/`false` | `true`                             | no       | Partitioned (CHIPS) cookie flag; matches the upstream default since v1.27.0      |
| `custom_bots`             | Array          |                                    | no       | Extra bot rules, appended after the imports as raw hashes                        |
| `default_challenge`       | Hash           | `fast`, difficulty `4`             | no       | Algorithm and difficulty for the single weight threshold                         |
| `ed25519_private_key_file`| String         | `/etc/anubis/<name>.key`           | no       | Where a generated key is persisted between runs                                  |
| `ed25519_private_key_hex` | String         | generated                          | no       | Hex signing key; set only for load-balanced pairs. See [Signing keys](#signing-keys) |
| `extra_config`            | Hash           |                                    | no       | Additional top-level policy-file keys (`store`, `metrics`, `honeypot`, ...)       |
| `extra_env`               | Hash           |                                    | no       | Additional environment variables, for settings with no property                  |
| `import_bots`             | Array          | `osl_anubis_default_bots`          | no       | `(data)/...` bot policy snippets to import                                       |
| `log_level`               | String         | `WARN`                             | no       | `SLOG_LEVEL` for anubis. See [Logging](#logging)                                 |
| `memory_limit`            | String         | half the host's RAM                | no       | `GOMEMLIMIT` for the Go runtime, e.g. `3GiB`. See [Memory and storage](#memory-and-storage) |
| `metrics_bind`            | String         | `:9090`                            | no       | Prometheus listener address; give each instance its own port                     |
| `policy_fname`            | String         | `/etc/anubis/botPolicies-<name>.yaml` | no    | Path to the generated policy file                                                |
| `redirect_domains`        | String         |                                    | no       | Comma-separated domains anubis may redirect to; see below                        |
| `serve_robots_txt`        | `true`/`false` | `false`                            | no       | Serve a `robots.txt` disallowing AI scrapers                                     |
| `store`                   | Hash           | `valkey@anubis`, or bbolt in `/var/lib/anubis/<name>/` | no | The policy file's `store` block. See [Memory and storage](#memory-and-storage) |
| `target`                  | String         |                                    | no       | Backend URL to reverse proxy valid requests to                                   |
| `valkey`                  | `true`/`false` | `true` on AlmaLinux 9.7+           | no       | Run `valkey@anubis` and default `store` to it                                    |
| `valkey_config_version`   | Integer        | `1`                                | no       | Bump to push a valkey setting change to an existing node                         |
| `valkey_maxmemory`        | String         | `2gb`                              | no       | valkey `maxmemory`                                                               |
| `valkey_port`             | Integer        | `6390`                             | no       | Port `valkey@anubis` listens on, on `127.0.0.1`                                  |
| `webmaster_email`         | String         |                                    | no       | Contact address shown on the reject page                                         |

## Examples

A standalone host. The signing key is generated on the first run and kept:

```ruby
osl_anubis 'default' do
  target 'http://127.0.0.1:8080'
  redirect_domains 'example.osuosl.org'
end
```

A load-balanced host with custom rules. Every backend in the pool gets the same
`ed25519_private_key_hex`:

```ruby
osl_anubis 'gitlab' do
  target 'http://127.0.0.1:8080'
  bind '127.0.0.1:8933'
  metrics_bind ':9091'
  redirect_domains 'gitlab.osuosl.org'
  ed25519_private_key_hex data_bag_item('anubis', 'keys')['gitlab']
  custom_bots [
    {
      'name' => 'static-assets',
      'path_regex' => '^/assets/.*$',
      'action' => 'ALLOW',
    },
  ]
end
```

## Memory and storage

Anubis keeps its challenge, cookie, DNS and Open Graph state in a store. The
store has to take a write for every challenge it issues, so under a crawl it is
the busiest thing on the host. Two backends have failed at OSUOSL:

- The upstream in-memory default grew to about 1 GiB of live heap in three days
  on the load balancer, and since the Go runtime lets resident memory run at
  roughly twice the live heap, the host went into swap.
- bbolt, on disk, commits every challenge as its own fsync'd transaction behind
  a single writer lock. Under a crawl the load balancer reached 185 MiB/s of
  sustained writes and anubis stalled for up to 38 minutes at a time.

So on AlmaLinux 9.7 and later, the first release with `valkey` in AppStream,
`valkey` defaults to true and the resource runs a local valkey for the store,
as the osl-valkey instance `valkey@anubis`:

- It listens on `127.0.0.1` at `valkey_port` (6390) only, with no RDB
  snapshots and no AOF, so nothing reaches disk and `vm.overcommit_memory` is
  left alone. `maxmemory` is `valkey_maxmemory` with `allkeys-lru`.
  Every key anubis writes carries its own TTL, so eviction only starts if
  that limit fills.
- valkey restarts on failure, and each `anubis@<name>.service` is ordered
  after it, since anubis pings its store once at startup and exits if it is
  not there.
- A stale `/var/lib/anubis/<name>/anubis.bdb` from an earlier bbolt store is
  deleted. Anubis holds the file open until it restarts onto valkey, so the
  space comes back then.

Things to know before relying on it:

- Every anubis instance on a host shares `valkey@anubis`, so they must all
  pass the same `valkey_*` settings. osl-valkey fails the converge if two
  declarations disagree.
- It is its own process with its own config (`/etc/valkey/anubis.conf`), data
  directory and port, so it can sit beside another valkey on the host, such
  as osl-openstack's coordination tier on the packaged `valkey.service`.
- valkey's configuration is seeded once, not converged. Changing
  `valkey_maxmemory` on an existing node does nothing until
  `valkey_config_version` is bumped, which rewrites the config and restarts
  valkey. The auth cookie is a signed JWT that needs no store, so a restart
  only drops challenges that were in flight.
- Pick another `valkey_port` if something else on the host already holds
  6390. osl-nextcloud's valkey on AlmaLinux 10 is not managed by osl-valkey,
  so its port is not checked.
- A caller that must never fall back, like the load balancer, sets
  `valkey true`, so a host without the package fails the converge rather than
  quietly running bbolt.

Elsewhere `valkey` defaults to false and `store` stays bbolt at
`/var/lib/anubis/<name>/anubis.bdb`. That is the unit's `StateDirectory`, so it
is writable by the `DynamicUser` and survives restarts, and each instance gets
its own database since bbolt takes an exclusive lock.

A `store` key in `extra_config` replaces the default either way, and the
upstream in-memory backend can still be chosen with
`store('backend' => 'memory')` for a throwaway instance.

`memory_limit` sets `GOMEMLIMIT` in the env file to half the host's RAM. It is
a soft limit: the runtime collects harder as it approaches it rather than
letting the heap double first. If live data exceeds it anubis keeps running but
spends more CPU on garbage collection, so raise it, or set it explicitly on
hosts that share memory with a heavier neighbour. A `GOMEMLIMIT` in `extra_env`
wins over the property.

## Logging

Anubis writes a line per challenge decision at its own `INFO` default. On the
OSUOSL load balancer that was four gigabytes a day into `/var/log/messages` and
the same again on the loghost, so `log_level` defaults to `WARN` instead.
Warnings and errors still log, including the `X-Real-Ip header is not set`
misconfiguration message.

Nothing is lost for triage. Every decision is exported as `anubis_policy_results`
and `anubis_challenges_*` for Prometheus, and the request itself is in the
reverse proxy's log. Set `log_level 'INFO'` on an instance you are debugging, or
`'DEBUG'` for anubis' own verbose output. A `SLOG_LEVEL` in `extra_env` wins
over the property.

## Signing keys

Anubis signs its challenge cookies with an ed25519 key. Left to itself it
generates a random one at every start, so each restart — including the one this
resource triggers on any config change — invalidates every outstanding cookie
and re-challenges every visitor.

So the resource always supplies one. It keeps the key in two places, and the
split matters:

- `ed25519_private_key_file` (`/etc/anubis/<name>.key`, `0600 root:root`) is
  where Chef persists the key between runs. Only Chef reads it.
- `ED25519_PRIVATE_KEY_HEX` in the env file is how anubis actually receives it.

The key is handed over inline rather than by path because the packaged
`anubis@.service` runs with `DynamicUser=yes`. Anubis would read a
`ED25519_PRIVATE_KEY_HEX_FILE` as that transient unprivileged user and cannot
open a root-owned key file, so it exits and systemd restarts it every 30s.
systemd reads `EnvironmentFile` as root before dropping privileges, so the env
file works. Both files are `0600 root:root`, and the env template is marked
sensitive.

**Standalone hosts need no configuration.** On the first run the resource
generates a key with `SecureRandom.hex(32)` and persists it; later runs read
that same value back, so the key survives converges, restarts and reboots.

**Load-balanced hosts must share a key**, or each backend will reject cookies
issued by the other. Set `ed25519_private_key_hex` on every host in the pool. An
explicit key always wins over whatever is on disk, so rotating it takes effect
on the next run.

Generate one with:

```
openssl rand -hex 32
```

That is a 32-byte seed as 64 hex characters; anubis rejects any other length.
Keep it in an encrypted data bag — never commit it or put it in an attribute:

```ruby
osl_anubis 'default' do
  target 'http://127.0.0.1:8080'
  ed25519_private_key_hex data_bag_item('anubis', 'keys')['default']
end
```

Changing the key — generated or explicit — restarts the instance and
re-challenges everyone once. To move a standalone host into a pool, read its
existing `ed25519_private_key_file`, put that value in the data bag, and set
`ed25519_private_key_hex` on both hosts so no one is re-challenged.

## Metrics

`metrics_bind` defaults to `:9090`, on every interface, and the resource always
opens that port with `osl_firewall_port` using `osl_only`. Our Prometheus can
scrape `http://<host>:9090/metrics`; everyone else is dropped.

Give every additional instance on a host its own `metrics_bind` port — a second
instance on `:9090` logs a bind error and silently runs without metrics. The
firewall rule follows whatever port `metrics_bind` names.

There is no way to switch the listener off in v1.27.0: an empty `METRICS_BIND`
is ignored and falls back to `:9090`, and a policy-file `metrics` block rejects
an empty `bind`. A `metrics` block in `extra_config` can add basic auth or TLS
on top.

Anubis counters only appear once traffic has been through them, so a freshly
started instance exports just the Go and process collectors.

## Redirect domains

Leaving `redirect_domains` unset makes anubis willing to redirect to any
domain. Anubis warns about this at every start, and the resource logs a Chef
warning on every run so it stays visible without reading the service log. Set
it to the domains the instance actually serves.

## Bot policies

`import_bots` defaults to `osl_anubis_default_bots`, which tracks upstream's
`(data)/meta/default-config.yaml`. The generated policy defines a single weight
threshold named `default-challenge` (`weight > 0`), matching anubis' built-in
`legacy-anubis-behaviour` default rather than the tiered ladder in upstream's
example `botPolicies.yaml`. Use `extra_config` to supply your own `thresholds`
list if you want the tiers.

Allowlists for small browsers (Dillo, NetSurf, Pale Moon) are opt-in upstream
and are not imported by default. Add them explicitly when needed:

```ruby
import_bots osl_anubis_default_bots + %w((data)/clients/small-internet-browsers/_permissive.yaml)
```
