osl_shell_function 'hello' do
  body 'echo "Hello, $@"'
end

osl_shell_function 'pcp_test' do
  body '/usr/bin/pcp_node_info -h localhost -p 9898 -U pgpool -w "$@"'
end

osl_shell_function 'remove' do
  action :remove
end
