user 'test_user_1'
user 'test_user_2'

%w(key_1 key_2 key_3).each do |k|
  osl_authorized_keys k do
    user 'test_user_1'
  end
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

%w(key_1 key_2).each do |k|
  osl_authorized_keys k do
    user 'test_user_2'
    action [:add, :remove]
  end
end
