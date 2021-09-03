user 'test_user_1'
user 'test_user_2'

osl_ssh_key 'id_rsa' do
  content 'test_key'
  user 'test_user_1'
  action :add
end
osl_ssh_key 'id_ed25519' do
  content 'test_key'
  user 'test_user_1'
  action :add
end
osl_ssh_key 'id_rsa' do
  content 'test_key'
  user 'test_user_1'
  action :remove
end

osl_ssh_key 'id_rsa' do
  content 'test_key'
  user 'test_user_2'
  action [:add, :remove]
end
