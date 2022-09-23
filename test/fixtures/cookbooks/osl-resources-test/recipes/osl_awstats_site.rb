#
# Cookbook:: awstats-test
# Recipe:: default
#
# Copyright:: 2022, The Authors, All Rights Reserved.

osl_awstats_site 'test.osuosl.org' do
  use_osl_mirror true
end

osl_awstats_site 'test-full' do
  use_osl_mirror true
  site_domain 'test-full.osuosl.org'
  host_aliases 'test.osuosl.org'
  log_file 'full'
  log_format %w(
    %time3
    %other
    %host
    %bytesd
    %url
    %other
    %other
    %method
    %other
    %logname
    %other
    %code
    %other
    %other
  )
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
