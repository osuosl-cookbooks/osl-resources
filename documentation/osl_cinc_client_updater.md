# osl_cinc_client_updater

Upgrade the Cinc Client package (`cinc`) to a version served by the Cinc Project. It replaces the `chef_client_updater`
cookbook for Linux hosts.

The resource installs the Cinc fork of the `mixlib-install` gem (`>= 4.1.2`) from `rubygems_url` and runs it in a
separate Ruby process, so no second copy of the gem is loaded into the running Chef process. The fork serves only the
highest package iteration of a version, so a respin such as `19.4.46-2` is chosen over `19.4.46-1`.

A bare version such as `'19'` or `'18.11'` resolves to the newest matching release and its newest iteration. The update
runs when the installed version differs from that release, or when it is the same version and the installed package
iteration (the RPM release or the Debian revision) is lower. A node that is already on the newest iteration, or whose
installed iteration cannot be read, is left alone.

To update, the resource moves `install_path` to `<install_path>.upgrade`, runs the install script for the artifact and
checks `<install_path>/bin/cinc-client --version`. If either step fails, the old install is moved back and the run
fails. The backup is removed on the next run that does not update. After a successful update the `post_install_action`
runs.

If the gem cannot be installed or the lookup fails (for example `rubygems.cinc.sh` or `packages.cinc.sh` is down), the
resource logs a warning and skips the update so the rest of the run still converges.

## Actions

| Action | Description |
| ------ | ----------- |
| `:update` | Update Cinc Client when needed (default) |

## Properties

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `version` | String | name | Version to install, such as `'19'`, `'18.11'` or `'19.4.46'`; a pinned iteration is not supported |
| `channel` | String | `'stable'` | Release channel |
| `rubygems_url` | String | `'https://rubygems.cinc.sh'` | Source for the `mixlib-install` gem |
| `install_path` | String | `'/opt/cinc'` | Directory the package installs to; moved aside during an update |
| `install_timeout` | Integer | `600` | Seconds the install script may run |
| `post_install_action` | String | `'kill'` | `kill` exits the Chef run with status 213 (and kills the supervisor when forked); `exec` re-runs Chef from the new install, and falls back to `kill` when forked |
| `exec_command` | String | the running program | Command `exec` runs |
| `exec_args` | Array | `ARGV` | Arguments `exec` passes |

## Examples

```ruby
osl_cinc_client_updater '19' do
  post_install_action 'exec'
end
```
