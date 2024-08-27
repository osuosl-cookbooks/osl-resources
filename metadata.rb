name             'osl-resources'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
source_url       'https://github.com/osuosl-cookbooks/osl-resources'
issues_url       'https://github.com/osuosl-cookbooks/osl-resources/issues'
license          'Apache-2.0'
chef_version     '>= 16.0'
description      'Holds base resources for the OSUOSL'
version          '2.0.3'

depends          'line'
depends          'osl-repos'
depends          'ark'

supports         'almalinux', '~> 8.0'
supports         'almalinux', '~> 9.0'
supports         'debian', '~> 12.0'
supports         'ubuntu', '~> 24.04'
