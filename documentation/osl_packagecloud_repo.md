# osl_packagecloud_repo

## Actions

- `:add`: Adds a packagecloud repository.
- `:remove`: Removes a packagecloud repository.

## Properties

| Property     | Type   | Default                   | Required | Description                            |
|--------------|--------|---------------------------|----------|----------------------------------------|
| `repository` | String | Resource Name             | yes      | Name of the repository                 |
| `base_url`   | String | `https://packagecloud.io` |          | Base url of the repository.            |

## Examples

Add a packagecloud repo from default URL:

```ruby
osl_packagecloud_repo 'varnishcache/varnish60lts'
```

Remove a packagecloud repo:

```ruby
osl_packagecloud_repo 'varnishcache/varnish40' do
  action :remove
end
```

Add a packagecloud repo from non-default URL:

```ruby
osl_packagecloud_repo 'varnishcache/varnish60lts' do
  base_url 'https://example.com'
end
```
