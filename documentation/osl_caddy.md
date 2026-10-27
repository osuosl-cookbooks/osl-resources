# osl_caddy

Installs [Caddy](https://caddyserver.com) from the `@caddy/caddy` Copr repo and
writes `/etc/caddy/Caddyfile`, which holds the global options and imports every
site file under `/etc/caddy/sites/`. Sites are added with
[osl_caddy_site](osl_caddy_site.md).

In Test Kitchen the global options also point Caddy's ACME client at the local
Pebble server from `osl-acme::server`.

## Actions

- `:install`: Installs Caddy, writes the Caddyfile and enables and starts the service (default)
- `:reload`: Reloads the service; notify this from `osl_caddy_site`

## Properties

| Property         | Type           | Default | Required | Description                                                       |
|------------------|----------------|---------|----------|-------------------------------------------------------------------|
| `global_options` | Array          | `[]`    | no       | Extra lines for the Caddyfile's global options block              |
| `metrics`        | `true`/`false` | `true`  | no       | Sets the `metrics` global option, which Caddy 2.8+ needs to export request counters |

## Examples

```ruby
osl_caddy 'default'

osl_caddy_site 'example.org' do
  content(
    'example.org' => {
      'log' => true,
      'reverse_proxy' => 'localhost:8080',
    }
  )
  notifies :reload, 'osl_caddy[default]'
end
```
