# osl-resources CHANGELOG

This file is used to list changes made in each version of the osl-resources cookbook.

2.0.2 (2024-08-23)
------------------
- Fix multiple ipv6 addresses with nmstate

2.0.1 (2024-07-26)
------------------
- Add support for Ubuntu

2.0.0 (2024-07-17)
------------------
- Support for AlmaLinux 9

1.11.0 (2024-07-02)
-------------------
- Remove support for CentOS 7

1.10.2 (2024-05-10)
-------------------
- Update testing to virtualbox 7.0

1.10.1 (2024-05-07)
-------------------
- Remove support for Debian 11

1.10.0 (2024-04-02)
-------------------
- Allow key to be an array in osl_authorized_keys

1.9.0 (2024-03-01)
------------------
- Create osl_udev_rules custom resource

1.8.0 (2024-02-16)
------------------
- Initial Hugo resource

1.7.1 (2023-07-31)
------------------
- Add support for debian 12

1.7.0 (2023-06-21)
------------------
- Change default action of osl_conntrackd to :create

1.6.0 (2023-06-15)
------------------
- osl_conntrackd resource

1.5.2 (2023-05-02)
------------------
- Remove CentOS Stream 8

1.5.1 (2023-04-18)
------------------
- Fix gpgkey used in yum repository for virtualbox

1.5.0 (2023-03-10)
-----------------
- Create osl_mongodb resource

1.4.1 (2023-02-24)
------------------
- Add AlmaLinux 8 support

1.4.0 (2023-02-09)
------------------
- Create osl_dnsdist resource

1.3.1 (2022-09-26)
------------------
- Improved awstats_site resource

1.3.0 (2022-09-01)
------------------
- Added osl_awstats_host

1.2.4 (2022-08-26)
------------------
- Migrate osl_local_ipv4? and osl_local_ipv6? methods from base cookbook

1.2.3 (2022-08-23)
------------------
- Use a short checksum of the key name for resource names

1.2.2 (2022-08-19)
------------------
- Add ipv6_autoconf parameter to osl_ifconfig

1.2.1 (2022-05-16)
------------------
- Work around constant upstream issues pulling gpg keys

1.2.0 (2022-04-15)
------------------
- Add osl_virtualbox resource

1.1.1 (2022-01-24)
------------------
- Add support for Debian on osl_fakenic

1.1.0 (2022-01-14)
------------------
- removing-support-debian-10

1.0.0 (2021-09-16)
------------------
- Initial PR

## 0.1.0

Initial release.

- change 0
- change 1
