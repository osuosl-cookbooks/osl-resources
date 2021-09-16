user 'test_user'

%w(key_1 key_2 key_3).each do |k|
  osl_authorized_keys k do
    user 'test_user'
  end
end
%w(key_1 key_2 key_3).each do |k|
  osl_authorized_keys k do
    user 'test_user'
    group 'root'
    dir_path '/opt/test/.ssh'
  end
end
