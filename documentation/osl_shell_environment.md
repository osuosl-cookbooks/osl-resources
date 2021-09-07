# osl_shell_environment

## Actions

- `add`: Adds an environment variable to /etc/profile.d/
- `remove`: Removes an environment variable from /etc/profile.d/

## Properties

| Property               | Type   | Default              | Required | Description                                         |
|------------------------|--------|----------------------|----------|-----------------------------------------------------|
| `environment_variable` | String | None                 | yes      | Variable name (name property)                       |
| `command`              | String | None                 | [:add]   | Content to set the variable to                      |
| `user`                 | String | 'root'               | no       | The user who owns the environment variable file     |
| `group`                | String | 'root'               | no       | The group who owns the environment variable file    |
| `mode`                 | String | None                 | yes      | The file permissions for the created shell file     |
| `destination`          | String | '/etc/profile.d/'    | no       | The location to create the file at                  |

## Examples

Add an alias.

```ruby
osl_shell_alias 'll' do
  command 'ls -l'
end
```

Remove an alias.

```ruby
osl_shell_alias 'remove' do
  action :remove
end
```
