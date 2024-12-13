resource_name :osl_geoip
provides :osl_geoip
default_action :create
unified_mode true

property :account_id, Integer, sensitive: true, required: true
property :license_key, String, sensitive: true, required: true
property :edition_ids, Array, default: %w(GeoLite2-ASN GeoLite2-City GeoLite2-Country)

action :create do
  include_recipe 'yum-osuosl'

  package 'geoipupdate'

  template '/etc/GeoIP.conf' do
    cookbook 'osl-resources'
    sensitive true
    mode '0640'
    variables(
      account_id: new_resource.account_id,
      license_key: new_resource.license_key,
      edition_ids: new_resource.edition_ids.sort.join(' ')
    )
  end

  cron_d 'geoipupdate' do
    predefined_value '@weekly'
    command '/usr/bin/geoipupdate > /dev/null'
  end
end
