# osl-resources Cookbook

This is the osl-resources cookbook for the OSL unmanaged and managed hosts.

## Platforms

The following platforms and versions are tested and supported using [test-kitchen](http://kitchen.ci/)

- AlmaLinux 8
- AlmaLinux 9
- AlmaLinux 10
- Ubuntu 24.04
- Debian 12
- Debian 13

## Resources

- [osl_anubis](documentation/osl_anubis.md)
- [osl_authorized_keys](documentation/osl_authorized_keys.md)
- [osl_chrony](documentation/osl_chrony.md)
- [osl_chrony_server](documentation/osl_chrony_server.md)
- [osl_dnf_copr](documentation/osl_dnf_copr.md)
- [osl_fakenic](documentation/osl_fakenic.md)
- [osl_ifconfig](documentation/osl_ifconfig.md)
- [osl_packagecloud_repo](documentation/osl_packagecloud_repo.md)
- [osl_route](documentation/osl_route.md)
- [osl_shell_alias](documentation/osl_shell_alias.md)
- [osl_shell_environment](documentation/osl_shell_environment.md)
- [osl_shell_function](documentation/osl_shell_function.md)
- [osl_ssh_key](documentation/osl_ssh_key.md)
- [osl_sysfs_param](documentation/osl_sysfs_param.md)
- [osl_systemd_unit_drop_in](documentation/osl_systemd_unit_drop_in.md)
- [osl_test_netns](documentation/osl_test_netns.md)

## Kitchen Dokken

This cookbook supports dokken testing. Dokken tests fail where they need to create network intefaces or otherwise
change kernel state that a container does not own. The following suites are *expected* to fail when using dokken.

- osl-fakenic
- osl-fakenic-delete
- osl-ifconfig
- osl-ifconfig-non-idempotent
- osl-route
- osl-route-remove
- osl-sysfs-param
- osl-sysfs-param-remove

## Contributing

1. Fork the repository on Github
1. Create a named feature branch (like `add_component_x`)
1. Write your change
1. Run vagrant up, ensuring your changes work
1. Submit a Pull Request using Github

## License and Authors

Authors: Oregon State University
