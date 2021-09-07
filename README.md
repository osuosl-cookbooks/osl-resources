# osl-resources Cookbook

This is the osl-resources cookbook for the OSL unmanaged and managed hosts.

## Platforms

The following platforms and versions are tested and supported using [test-kitchen](http://kitchen.ci/)

- CentOS 7/8
- Debian 10/11
- Ubuntu 18.04 / 20.04

## Resources

- [osl_authorized_keys](https://github.com/osuosl-cookbooks/osl-resources/blob/REK/Initial_PR/documentation/osl_authorized_keys.md)
- [osl_fakenic](https://github.com/osuosl-cookbooks/osl-resources/blob/REK/Initial_PR/documentation/osl_fakenic.md)
- [osl_ifconfig](https://github.com/osuosl-cookbooks/osl-resources/blob/REK/Initial_PR/documentation/osl_ifconfig.md)
- [osl_packagecloud_repo](https://github.com/osuosl-cookbooks/osl-resources/blob/REK/Initial_PR/documentation/osl_packagecloud_repo.md)
- [osl_route](https://github.com/osuosl-cookbooks/osl-resources/blob/REK/Initial_PR/documentation/osl_route.md)
- [osl_shell_alias](https://github.com/osuosl-cookbooks/osl-resources/blob/REK/Initial_PR/documentation/osl_shell_alias.md)
- [osl_shell_environment](https://github.com/osuosl-cookbooks/osl-resources/blob/REK/Initial_PR/documentation/osl_shell_environment.md)
- [osl_ssh_key](https://github.com/osuosl-cookbooks/osl-resources/blob/REK/Initial_PR/documentation/osl_ssh_key.md)
- [osl_systemd_unit_drop_in](https://github.com/osuosl-cookbooks/osl-resources/blob/REK/Initial_PR/documentation/osl_systemd_unit_drop_in.md)

## Kitchen Dokken

This cookbook supports dokken testing. Dokken tests fail where they need to create network intefaces. The following
suites are *expected* to fail when using dokken.

- osl-fakenic
- osl-fakenic-delete
- osl-ifconfig
- osl-ifconfig-non-idempotent
- osl-route
- osl-route-remove

## Contributing

1. Fork the repository on Github
1. Create a named feature branch (like `add_component_x`)
1. Write your change
1. Run vagrant up, ensuring your changes work
1. Submit a Pull Request using Github

## License and Authors

Authors: Open Source Lab
