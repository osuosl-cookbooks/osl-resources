user 'test_user'

directory '/home/test_user/.ssh' do
  owner 'test_user'
  group 'test_user'
  mode '0700'
  recursive true
end

# A stray key and a duplicate, as on a host whose data bag dropped a key; seeded once
file '/home/test_user/.ssh/authorized_keys' do
  content "stray_key\nkey_1\nkey_1\n"
  owner 'test_user'
  group 'test_user'
  mode '0600'
  action :create_if_missing
end

osl_authorized_keys 'test_user' do
  key %w(key_1 key_1)
  user 'test_user'
  exclusive true
end

osl_authorized_keys 'key_2' do
  user 'test_user'
  exclusive true
end
