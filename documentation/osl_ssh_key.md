# osl_ssh_key

## Actions

- `:add`: Adds a key to the specified `dir_path`.
- `:remove`: Removes a key from the specified `dir_path`.

## Properties

| Property   | Type   | Default          | Required | Description                                          |
|------------|--------|------------------|----------|------------------------------------------------------|
| `key_name` | String | Resource Name    | yes      | Key name                                             |
| `content`  | String |                  | `:add`   | The content of the `key_name` file                   |
| `user`     | String |                  | yes      | The user who owns the `key_name` file at `dir_path`  |
| `group`    | String | `user`           |          | The group who owns the `key_name` file at `dir_path` |
| `dir_path` | String | `/home/#{user}'` |          | Path to the directory containing the `key_name` file |

## Examples

Add a key with default properties:

```ruby
osl_ssh_key 'id_rsa' do
  user 'test_user_1'
  content 'test_key'
end
```

Add a key with non-default properties:

```ruby
osl_ssh_key 'id_ed25519' do
  user 'test_user_2'
  group 'nobody'
  dir_path '/opt/test/.ssh'
  content 'curvy_key'
end
```

Remove a key:

```ruby
osl_ssh_key 'id_rsa' do
  user 'test_user_3'
  action :remove
end
```
