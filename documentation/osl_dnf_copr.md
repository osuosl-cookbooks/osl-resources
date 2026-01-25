# osl_dnf_copr

Manage Fedora COPR repositories using DNF.

## Actions

| Action | Description |
| ------ | ----------- |
| `:enable` | Enable a COPR repository (default) |
| `:disable` | Disable a COPR repository |

## Properties

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `copr` | String | name | The COPR repository in `owner/project` format |

## Examples

### Enable a COPR repository

```ruby
osl_dnf_copr 'rapier1/hpnssh'
```

### Disable a COPR repository

```ruby
osl_dnf_copr 'rapier1/hpnssh' do
  action :disable
end
```

### Using a different name

```ruby
osl_dnf_copr 'hpnssh' do
  copr 'rapier1/hpnssh'
end
```

## Notes

- This resource only works on RHEL-based systems (AlmaLinux, CentOS, Fedora, etc.)
- The `dnf-plugins-core` package is automatically installed when enabling a COPR repository
- COPR repositories are created at `/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:<owner>:<project>.repo`
