# osl_fakenic

## Actions

- `:create`: Creates a dummy interface (default action)
- `:delete`: Deletes a dummy interface

## Properties

| Property       | Type          | Default         | Required | Description                                          |
|----------------|---------------|-----------------|----------|------------------------------------------------------|
| `interface`    | String        | Resource Name   | yes      | Name for the interface                               |
| `ip4`          | String, Array |                 | yes      | IPv4 address(s) to assign to the interface           |
| `ip6`          | String, Array |                 |          | IPv6 address(s) to assign to the interface           |
| `mac_address`  | String        |                 |          | Mac address to assign to the interface               |
| `multicast`    | true, false   | false           |          | Whether or not to enable multicast for the interface |

## Examples

Create dummy interface with minimum properties:

```ruby
osl_fakenic 'eth2' do
  ip4 '192.168.0.1/24'
  ip6 'fe80::1/64'
  mac_address '00:1a:4b:a6:a7:c4'
  multicast true
end
```

Create dummy interface with all properties:

```ruby
osl_fakenic 'eth2' do
  ip4 '192.168.0.1/24'
  ip6 'fe80::1/64'
  mac_address '00:1a:4b:a6:a7:c4'
  multicast true
end
```

Remove dummy interface:

```ruby
  osl_fakenic 'eth2' do
    action :remove
  end
```
