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

- [osl_authorized_keys](documentation/osl_authorized_keys.md)
- [osl_fakenic](documentation/osl_fakenic.md)
- [osl_ifconfig](documentation/osl_ifconfig.md)
- [osl_ipmi_user](documentation/osl_ipmi_user.md)
- [osl_packagecloud_repo](documentation/osl_packagecloud_repo.md)
- [osl_route](documentation/osl_route.md)
- [osl_shell_alias](documentation/osl_shell_alias.md)
- [osl_shell_environment](documentation/osl_shell_environment.md)
- [osl_shell_function](documentation/osl_shell_function.md)
- [osl_ssh_key](documentation/osl_ssh_key.md)
- [osl_systemd_unit_drop_in](documentation/osl_systemd_unit_drop_in.md)

## Kitchen Dokken

This cookbook supports dokken testing. Dokken tests fail where they need to create network interfaces. The following
suites are *expected* to fail when using dokken.

- osl-fakenic
- osl-fakenic-delete
- osl-ifconfig
- osl-ifconfig-non-idempotent
- osl-route
- osl-route-remove

## Kitchen Libvirt (IPMI Testing)

IPMI user management tests require hardware emulation using QEMU/KVM VMs with
OpenIPMI's `ipmi_sim` BMC simulation. These suites are only available in
`kitchen.libvirt.yml`:

- osl-ipmi-user
- osl-ipmi-user-delete
- osl-ipmi-user-modify

See [osl_ipmi_user documentation](documentation/osl_ipmi_user.md) for setup
prerequisites and detailed testing instructions.

## Contributing

1. Fork the repository on Github
1. Create a named feature branch (like `add_component_x`)
1. Write your change
1. Run vagrant up, ensuring your changes work
1. Submit a Pull Request using Github

## License and Authors

Authors: Oregon State University
