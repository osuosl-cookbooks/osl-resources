# osl_shell_function

## Actions

- `:add`: Adds a shell function to `/etc/profile.d/`
- `:remove`: Removes a shell function from `/etc/profile.d/`

## Properties

| Property        | Type   | Default       | Required | Description                                                    |
|-----------------|--------|---------------|----------|----------------------------------------------------------------|
| `function_name` | String | Resource Name | yes      | Function name                                                  |
| `body`          | String |               | `:add`   | The body of the shell function. Use `"$@"` to pass arguments.  |

## Examples

Add a function that passes through arguments:

```ruby
osl_shell_function 'pcp_node_info' do
  body '/usr/bin/pcp_node_info -h localhost -p 9898 -U pgpool -w "$@"'
end
```

This creates a shell function that allows:

```bash
# Use with default args
pcp_node_info

# Add extra arguments
pcp_node_info -n 0 -v
```

Add a simple function:

```ruby
osl_shell_function 'hello' do
  body 'echo "Hello, $@"'
end
```

Remove a function:

```ruby
osl_shell_function 'hello' do
  action :remove
end
```
