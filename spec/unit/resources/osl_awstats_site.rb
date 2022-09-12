require_relative '../../spec_helper'

describe 'osl_awstats_site' do
  platform 'centos'
  step_into :osl_awstats_site

  recipe do
    osl_awstats_site 'test.osuosl.org' do
      use_osl_mirror true
    end

    osl_awstats_site 'test-full' do
      use_osl_mirror true
      site_domain 'test-full.osuosl.org'
      host_aliases 'test.osuosl.org'
      log_file 'full'
      vsftp_logs true
      options(
        optionA: true,
        optionB: 50
      )
    end

    osl_awstats_site 'non-osl-mirror.example.com' do
      use_osl_mirror false
      log_file 'external-mirror'
    end

    osl_awstats_site 'date-append.osuosl.org' do
      use_osl_mirror true
      log_file 'custom'
      append_date true
    end
  end

  it do
    is_expected.to create_template('/etc/awstats/awstats.test.osuosl.org.conf').with(
      cookbook: 'osl-resources',
      source: 'awstats_site.conf.erb',
      variables: {
        log_file: '/usr/share/awstats/tools/logresolvemerge.pl /var/lib/awstats/logs/ftp-osl/*.log /var/lib/awstats/logs/ftp-chi/*.log /var/lib/awstats/logs/ftp-nyc/*.log |',
        site_domain: 'test.osuosl.org',
        host_aliases: '',
        log_format: %w(
          %virtualname
          %host
          %other
          %logname
          %time1
          %methodurl
          %code
          %bytesd
          %refererquot
          %uaquot
          %other
        ).join(' '),
        only_files: '',
        options: {},
      }
    )
  end

  it do
    is_expected.to create_template('/etc/awstats/awstats.test-full.conf').with(
      cookbook: 'osl-resources',
      source: 'awstats_site.conf.erb',
      variables: {
        log_file: '/usr/share/awstats/tools/logresolvemerge.pl /var/lib/awstats/logs/ftp-osl_ftp/full.log /var/lib/awstats/logs/ftp-chi_ftp/full.log /var/lib/awstats/logs/ftp-nyc_ftp/full.log |',
        site_domain: 'test-full.osuosl.org',
        host_aliases: 'test.osuosl.org',
        log_format: %w(
          %virtualname
          %host
          %other
          %logname
          %time1
          %methodurl
          %code
          %bytesd
          %refererquot
          %uaquot
          %other
        ).join(' '),
        only_files: '',
        options: {
          optionA: true,
          optionB: 50,
        },
      }
    )
  end

  it do
    is_expected.to create_template('/etc/awstats/awstats.non-osl-mirror.example.com.conf').with(
      cookbook: 'osl-resources',
      source: 'awstats_site.conf.erb',
      variables: {
        log_file: 'external-mirror.log',
        site_domain: 'non-osl-mirror.example.com',
        host_aliases: '',
        log_format: %w(
          %virtualname
          %host
          %other
          %logname
          %time1
          %methodurl
          %code
          %bytesd
          %refererquot
          %uaquot
          %other
        ).join(' '),
        only_files: '',
        options: {},
      }
    )
  end

  it do
    is_expected.to create_template('/etc/awstats/awstats.date-append.osuosl.org.conf').with(
      cookbook: 'osl-resources',
      source: 'awstats_site.conf.erb',
      variables: {
        log_file: '/usr/share/awstats/tools/logresolvemerge.pl /var/lib/awstats/logs/ftp-osl/custom-%YYYY-2%MM-2%DD-2.log /var/lib/awstats/logs/ftp-chi/custom-%YYYY-2%MM-2%DD-2.log /var/lib/awstats/logs/ftp-nyc/custom-%YYYY-2%MM-2%DD-2.log |',
        site_domain: 'date-append.osuosl.org',
        host_aliases: '',
        log_format: %w(
          %virtualname
          %host
          %other
          %logname
          %time1
          %methodurl
          %code
          %bytesd
          %refererquot
          %uaquot
          %other
        ).join(' '),
        only_files: '',
        options: {},
      }
    )
  end
end
