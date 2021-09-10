# osl_shell_alias

## Actions

- `:add`: Adds a command alias to /etc/profile.d/
- `:remove`: Removes a command alias from /etc/profile.d/

## Properties

| Property       | Type   | Default       | Required | Description                 |
|----------------|--------|---------------|----------|-----------------------------|
| `alias_name`   | String | Resource Name | yes      | Alias name                  |
| `command`      | String |               | [:add]   | Command to set the alias to |

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
