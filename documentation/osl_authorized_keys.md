# osl_authorized_keys

## Actions

- `:add`: Adds a key from selected file.
- `:remove`: Removes a key from selected file.

## Properties

| Property     | Type   | Default              | Required | Description                                                 |
|--------------|--------|----------------------|----------|-------------------------------------------------------------|
| `key`        | String | Resource Name        | yes      | The ssh public key to be added                              |
| `user`       | String |                      | yes      | The user who owns the `authorized_keys` file at `dir_path`  |
| `group`      | String | `user`               |          | The group who owns the `authorized_keys` file at `dir_path` |
| `dir_path`   | String | `/home/#{user}/.ssh` |          | Path to the directory containing the `authorized_keys` file |

## Examples

Add three keys to a user's authorized_keys file with minimum properties:

```ruby
osl_authorized_keys 'key_name' do
  key 'id-ed255 ... = x@test.org'
  user 'example_user'

['id-ed ... x@test.org' 'id-rsa ... x@test.org'].each do |k|
  osl_authorized_keys k do
    user 'example_user'
  end
end
```

Add three keys to a user's authorized_keys file with non-default `dir_path` and `group`:

```ruby
%w(key_1 key_2 key_3).each do |k|
  osl_authorized_keys k do
    user 'example_user'
    group 'root'
    dir_path '/opt/test/.ssh'
  end
end
```

Remove keys from a user's authorized_keys file:

```ruby
%w(key_1 key_2).each do |k|
  osl_authorized_keys k do
    user 'example_user'
    action :remove
  end
end
```
