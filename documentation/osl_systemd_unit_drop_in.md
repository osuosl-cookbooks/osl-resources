# osl_systemd_unit_drop_in

## Actions

- `:create`: Creates a systemd drop-in unit file.
- `:delete`: Deletes a systemd drop-in unit file.

## Properties

| Property          | Type           | Default          | Required  | Description                                                       |
|-------------------|----------------|------------------|-----------|-------------------------------------------------------------------|
| `override_name`   | String         | Resource Name    | yes       | Override file name                               |
| `content`         | [String, Hash] |                  | [:create] | The content of the unit file (will be converted to INI if a Hash) |
| `unit_name`       | String         |                  | yes       | The service name for the unit                                     |
| `triggers_reload` | true, false    | true             | no        | Should this trigget a reload of the service                       |
| `instance`        | String         | 'system'         | no        | `system` or `user` unit                                           |

## Examples

Create a drop-in unit at `/etc/systemd/system/testing/default.conf`

```ruby
osl_systemd_unit_drop_in 'default' do
  unit_name 'testing'
  content({
    'Unit' => {
      'Key1' => 'Val1',
      'Key2' => 'Val2',
    },
    'Service' => {
      'Key3' => 'Val3',
    },
  })
end
```

Create a drop-in unit with heredoc

```ruby
osl_systemd_unit_drop_in 'default' do
  unit_name 'testing'
  content <<~EOF
    [Unit]
    Key1=Val1
    Key2=Val2

    [Service]
    Key3=Val3
  EOF
  triggers_reload false
end
```

Create a drop-in unit at `/etc/systemd/user/testing/default.conf`

```ruby
osl_systemd_unit_drop_in 'default' do
  unit_name 'testing'
  instance 'user'
  content <<~EOF
  [Unit]
    Key1=Val1
    Key2=Val2

    [Service]
    Key3=Val3
  EOF
end
```

Delete a drop-in unit

```ruby
osl_systemd_unit_drop_in 'default' do
  unit_name 'testing'
  action :delete
end
```
