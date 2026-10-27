# osl_caddy_site

Manages one site file, `/etc/caddy/sites/<site_name>.caddyfile`, which the
Caddyfile from [osl_caddy](osl_caddy.md) imports. The resource doesn't reload
Caddy itself, so notify `osl_caddy[<name>]` with `:reload`.

## Actions

- `:create`: Writes the site file (default)
- `:delete`: Removes the site file, for example the old name's file after a
  rename. `content` isn't needed.

## Properties

| Property    | Type         | Default       | Required  | Description                              |
|-------------|--------------|---------------|-----------|------------------------------------------|
| `site_name` | String       | Resource Name | yes       | Name of the file under `/etc/caddy/sites/` |
| `content`   | String, Hash |               | `:create` | The site's Caddyfile, as text or as a Hash |

## Hash content

A Hash is rendered by `render_caddy_site_from_hash`. Each top-level key is a
site address and its value holds that site's directives:

- a Hash value is a block: `'route /special/*' => { ... }`
- `true`, `false` or `nil` writes the directive alone: `'log' => true`
- a String or number is the directive's argument: `'root' => '* /var/www/site'`
- an Array repeats the directive once per element, and a Hash element becomes
  a block for that directive
- `raw_lines` takes an Array of lines written as they are

## Examples

Create a site from a String:

```ruby
osl_caddy_site 'simple.example.org' do
  content <<~EOF
    simple.example.org {
      log
      respond "Hello from a simple site!"
    }
  EOF
  notifies :reload, 'osl_caddy[default]'
end
```

Create a site from a Hash:

```ruby
osl_caddy_site 'hash.example.org' do
  content(
    'hash.example.org' => {
      'log' => true,
      'root' => '* /var/www/hash.example.org',
      'file_server' => true,
      'header' => ['-Server', 'X-Frame-Options SAMEORIGIN'],
    }
  )
  notifies :reload, 'osl_caddy[default]'
end
```

Delete a site:

```ruby
osl_caddy_site 'old.example.org' do
  action :delete
  notifies :reload, 'osl_caddy[default]'
end
```
