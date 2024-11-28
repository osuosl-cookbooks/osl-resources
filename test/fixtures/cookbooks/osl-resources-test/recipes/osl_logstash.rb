osl_opensearch 'default'

osl_opensearch_user 'logstash' do
  password 'aec8de2ieP0i'
  backend_roles %w(logstash)
end

osl_logstash 'default'
