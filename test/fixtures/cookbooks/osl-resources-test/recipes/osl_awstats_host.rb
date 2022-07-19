#
# Cookbook:: awstats-test
# Recipe:: default
#
# Copyright:: 2022, The Authors, All Rights Reserved.

osl_awstats_host 'test' do
  site_domain 'test.osuosl.org'
end

osl_awstats_host 'test-full' do
  site_domain 'test-full.osuosl.org'
  host_aliases ['test.osuosl.org']
  log_file 'full.log'
  using_ftp_dir true
  options(
    optionA: true,
    optionB: 50
  )
end
