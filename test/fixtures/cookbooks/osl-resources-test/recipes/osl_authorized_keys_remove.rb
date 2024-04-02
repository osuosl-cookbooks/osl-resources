user 'test_user_1'
user 'test_user_2'

osl_authorized_keys 'test_user_1' do
  key %w(key_1 key_2 key_3)
  user 'test_user_1'
end

osl_authorized_keys 'key_2' do
  user 'test_user_1'
  action :remove
end

directory '/home/test_user_2/.ssh' do
  owner 'test_user_2'
  group 'test_user_2'
  mode '0700'
  recursive true
  action :create
end

file '/home/test_user_2/.ssh/id_rsa' do
  content 'test_key'
  owner 'test_user_2'
  group 'test_user_2'
  mode '0600'
end

osl_authorized_keys 'test_user_2' do
  key %w(key_1 key_2)
  user 'test_user_2'
  action [:add, :remove]
end
