# osl_packagecloud_repo

## Actions

- `Add`: Adds a packagecloud repository.
- `Remove`: Removes a packagecloud repository.

## Properties

| Property     | Type   | Default                   | Required | Description                            |
|--------------|--------|---------------------------|----------|----------------------------------------|
| `repository` | String | None                      | yes      | Name of the repository (name property) |
| `base_url`   | String | [https://packagecloud.io] | no       | Base url of the repository.            |

## Examples

Add a packagecloud repo from default URL

```ruby
osl_packagecloud_repo 'varnishcache/varnish60lts'
```

Remove a packagecloud repo

```ruby
osl_packagecloud_repo 'varnishcache/varnish40' do
  action :remove
end
```

Add a packagecloud repo from non-default URL

```ruby
osl_packagecloud_repo 'varnishcache/varnish60lts' do
  base_url 'https://example.com'
end
```
