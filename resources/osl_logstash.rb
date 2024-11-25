resource_name :osl_logstash
provides :osl_logstash
default_action :create
unified_mode true

# INFO: example property -- see https://docs.chef.io/custom_resources/
# property :foo, String, default: 'bar', description: 'Example property.'

action :create do
  include_recipe 'osl-repos::elasticsearch'

  package 'logstash'
end
