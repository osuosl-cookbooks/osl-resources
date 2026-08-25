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
| `metrics_bind`            | String         | `:9090`                            | no       | Prometheus listener address; give each instance its own port                     |
| `policy_fname`            | String         | `/etc/anubis/botPolicies-<name>.yaml` | no    | Path to the generated policy file                                                |
| `redirect_domains`        | String         |                                    | no       | Comma-separated domains anubis may redirect to; see below                        |
| `serve_robots_txt`        | `true`/`false` | `false`                            | no       | Serve a `robots.txt` disallowing AI scrapers                                     |
| `target`                  | String         |                                    | no       | Backend URL to reverse proxy valid requests to                                   |
| `webmaster_email`         | String         |                                    | no       | Contact address shown on the reject page                                         |

## Examples

A standalone host. The signing key is generated on the first run and kept:

```ruby
osl_anubis 'default' do
  target 'http://127.0.0.1:8080'
  redirect_domains 'example.osuosl.org'
end
```

A load-balanced host with custom rules and a persistent store. Every backend in
the pool gets the same `ed25519_private_key_hex`:

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
  extra_config(
    'store' => {
      'backend' => 'bbolt',
      'parameters' => { 'path' => '/var/lib/anubis/gitlab/store.bdb' },
    }
  )
end
```

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
