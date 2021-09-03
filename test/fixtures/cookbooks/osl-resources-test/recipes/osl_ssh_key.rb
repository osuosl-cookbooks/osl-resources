user 'test_user'

osl_ssh_key 'id_rsa' do
  content 'test_key'
  user 'test_user'
end

osl_ssh_key 'id_rsa.pub' do
  content 'test_key_pub'
  user 'test_user'
end

osl_ssh_key 'id_ed25519' do
  user 'test_user'
  content 'curvy_key'
  group 'root'
  dir_path '/opt/test/.ssh'
end
