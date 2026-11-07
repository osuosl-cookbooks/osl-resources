# osl_authorized_keys

## Actions

- `:add`: Makes the user's `authorized_keys` file hold only the declared keys. With `exclusive false`, it only appends
  missing keys.
- `:remove`: Removes keys from the user's `authorized_keys` file. A line is removed only when it matches the key exactly.

## Properties

| Property     | Type            | Default              | Required | Description                                                                 |
|--------------|-----------------|----------------------|----------|-----------------------------------------------------------------------------|
| `key`        | String, Array   | Resource Name        | yes      | The ssh public key or keys to add or remove                                 |
| `user`       | String          |                      | yes      | The user who owns the `authorized_keys` file at `dir_path`                  |
| `group`      | String          | `user`               |          | The group who owns the `authorized_keys` file at `dir_path`                 |
| `dir_path`   | String          | `/home/#{user}/.ssh` |          | Path to the directory containing the `authorized_keys` file                 |
| `exclusive`  | true, false     | `true`               |          | Make the file hold only the keys Chef declares, removing any other line     |

## Exclusive mode

By default the file is rewritten to hold exactly the declared keys, so a key dropped from a data bag is removed from
the host on the next run. Set `exclusive false` only for a file that must keep keys Chef doesn't manage; `:add` then
only appends missing keys, as it did before exclusive became the default.

- Every exclusive `:add` for the same file in a run adds its keys to one file, so a per-key loop works. Keys are
  written once each, in the order the declarations ran, and the file is mode `0600`.
- The file is written once, at the end of the Chef run. A run that fails leaves the old file in place, so a failure
  never writes part of a key list. Key changes land only on a clean run.
- A `:remove` anywhere in the run takes its keys out of the written file, whether it comes before or after the
  `:add`. When it removes every declared key, the merged write is skipped and any other lines in the file stay.
- An `exclusive false` `:add` on the same file as an exclusive one raises, naming both resources, because the two
  would rewrite each other on every run. Exclusive declarations for one file must also agree on `user` and `group`.
- An exclusive declaration with no keys logs a warning and leaves the file as it is, so an empty or missing list
  never wipes a user's keys.
- Other resources writing the same file (a plain `file` or `template`) are not seen and will fight with it.

## Examples

Add keys to a user's authorized_keys file with minimum properties:

```ruby
osl_authorized_keys 'key_name' do
  key 'ssh-ed25519 ... x@test.org'
  user 'example_user'
end

['ssh-ed25519 ... x@test.org', 'ssh-rsa ... x@test.org'].each do |k|
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

Keep only the keys from a data bag in a user's authorized_keys file (the default):

```ruby
osl_authorized_keys 'example_user' do
  key data_bag_item('users', 'example_user')['ssh_keys']
  user 'example_user'
end
```

Add a key but keep any other lines already in the file:

```ruby
osl_authorized_keys 'ssh-ed25519 ... x@test.org' do
  user 'example_user'
  exclusive false
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
