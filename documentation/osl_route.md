# osl_route

## Actions

- `:add`: Adds a route to the route table.
- `:remove`: Removes a route from the route table.

## Properties

| Property     | Type   | Default       | Required | Description            |
|--------------|--------|---------------|----------|------------------------|
| `device`     | String | Resource Name | yes      | The device to target   |
| `routes`     | Array  |               | [:add]   | A Hash array of routes |

## Examples

Add a route.

```ruby
osl_route 'eth1' do
  routes [
    {
      address: '10.50.0.0',
      netmask: '255.255.254.0',
      gateway: '10.30.0.1',
    },
  ]
end
```

Remove a route.

```ruby
osl_route 'eth3' do
  action :remove
end
```
