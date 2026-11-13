# osl_pagefind

Install the [Pagefind](https://pagefind.app/) static search indexer from its GitHub releases.

Pagefind is unpacked into `/opt/pagefind-<version>` and linked as `/usr/local/bin/pagefind`. Each converge installs
the highest final release matching the version prefix, so it tracks new releases unless pinned.

## Actions

| Action | Description |
| ------ | ----------- |
| `:install` | Install Pagefind (default) |

## Properties

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `version` | String | `'1'` | Pagefind version prefix, such as `'1.6'` or `'1.6.0'` |

## Examples

### Install the latest Pagefind 1.x

```ruby
osl_pagefind 'default'
```

### Pin a release

```ruby
osl_pagefind 'default' do
  version '1.6.0'
end
```
