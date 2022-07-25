#
# Cookbook:: awstats-test
# Recipe:: default
#
# Copyright:: 2022, The Authors, All Rights Reserved.

osl_awstats_site 'test.osuosl.org'

osl_awstats_site 'test-full' do
  site_domain 'test-full.osuosl.org'
  host_aliases ['test.osuosl.org']
  log_file 'full.log'
  vsftp_logs true
  options(
    optionA: true,
    optionB: 50
  )
end

osl_awstats_site 'non-osl-mirror.example.com' do
  use_osl_mirror false
  log_file 'external-mirror.log'
end

osl_awstats_site 'date-append.osuosl.org' do
  log_file 'custom.log'
  append_date true
end
