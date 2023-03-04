osl_mongodb '6.0' do
  data_dir '/var/lib/mongo2/'
  log_dest 'syslog'
  port 27019
  bind_ip '0.0.0.0'
  max_connections 5120
  forking 'true'
  pid_file_path '/var/run/mongodb/mongod.pid'
end
