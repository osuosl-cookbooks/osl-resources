# First create the users
osl_ipmi_user 'testadmin' do
  password 'TestAdminPass123!'
  privilege :administrator
end

osl_ipmi_user 'testoperator' do
  password 'TestOperatorPass123!'
  privilege :operator
end

# Then delete one of them
osl_ipmi_user 'testoperator' do
  action :delete
end
