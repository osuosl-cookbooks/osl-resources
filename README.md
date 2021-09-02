# osl-resources Cookbook

This is the osl-resources cookbook for the OSL unmanaged and managed hosts.

## Platforms

The following platforms and versions are tested and supported using [test-kitchen](http://kitchen.ci/)

- CentOS 7/8
- Debian 10/11
- Ubuntu 18.04 / 20.04

## Resources

- `osl_authorzed_keys`: Manages an `authorized_keys` file to add or remove public keys.
- `osl_fakenic`:  Manages `dummy` NICs. (RHEL Only)
- `osl_ifconfig`: Manages network interfaces. (RHEL Only)
- `osl_packagecloud_repo`: Manages PackageCloud repos.
- `osl_route`:    Manages routes. (RHEL Only)
- `osl_shell_alias`: Creates and manages shell aliases.
- `osl_shell_environment`: Creates and manages shell environment variables.
- `osl_ssh_key`: Manages public and private ssh keys.
- `osl_systemd_unit_drop_in`: Creates and manages systemd_unit drop-in files.

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
