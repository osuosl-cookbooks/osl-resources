user 'test_user'

osl_ssh_key 'id_rsa' do
  key 'test_key'
  user 'test_user'
end

osl_ssh_key 'id_rsa.pub' do
  key 'test_key_pub'
  user 'test_user'
end

osl_ssh_key 'id_ed25519' do
  user 'test_user'
  key 'curvy_key'
  group 'root'
  dir_path '/opt/test/.ssh'
end
