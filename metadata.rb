name             'osl-resources'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
source_url       'https://github.com/osuosl-cookbooks/osl-resources'
issues_url       'https://github.com/osuosl-cookbooks/osl-resources/issues'
license          'Apache-2.0'
chef_version     '>= 16.0'
description      'Holds base resources for the OSUOSL'
version          '1.5.1'

depends          'line'
depends          'osl-repos'

supports         'almalinux', '~> 8.0'
supports         'centos', '~> 7.0'
supports         'centos_stream', '~> 8.0'
supports         'debian', '~> 11.0'
