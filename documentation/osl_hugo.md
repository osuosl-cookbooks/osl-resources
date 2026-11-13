# osl_hugo

Install the [Hugo](https://gohugo.io/) static site generator and the [Dart Sass](https://sass-lang.com/dart-sass/)
binary Hugo uses to compile Sass, both from their GitHub releases.

Hugo is unpacked into `/opt/hugo-<version>` and linked as `/usr/local/bin/hugo`. Dart Sass is unpacked into
`/opt/dart-sass-<version>` and linked as `/usr/local/bin/sass`, where Hugo finds it on `PATH`. Each converge installs
the highest final release matching each version prefix, so both track new releases unless pinned.

Hugo 0.170.0 removed LibSass and the extended build. From 0.170.0 on the standard archive is installed; older versions
install the extended archive so `toCSS` keeps working with LibSass.

If no Hugo release matches `version`, the resource logs a warning and leaves Hugo alone. If no Dart Sass release
matches `dart_sass_version`, the converge fails.

## Actions

| Action | Description |
| ------ | ----------- |
| `:install` | Install Hugo and Dart Sass (default) |

## Properties

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `version` | String | `'0'` | Hugo version prefix, such as `'0.170'` or `'0.170.0'` |
| `dart_sass_version` | String | `'1'` | Dart Sass version prefix, such as `'1.108'` or `'1.108.2'` |

## Examples

### Install the latest Hugo and Dart Sass

```ruby
osl_hugo 'default'
```

### Pin both, for example to roll back a release that breaks a site build

```ruby
osl_hugo 'default' do
  version '0.169'
  dart_sass_version '1.108.2'
end
```
