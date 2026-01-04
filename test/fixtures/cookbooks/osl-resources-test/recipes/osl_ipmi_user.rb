# Create an administrator user
osl_ipmi_user 'testadmin' do
  password 'TestAdminPass123!'
  privilege :administrator
end

# Create an operator user
osl_ipmi_user 'testoperator' do
  password 'TestOperatorPass123!'
  privilege :operator
  channel 1
end

# Create a disabled user
osl_ipmi_user 'testdisabled' do
  password 'TestDisabledPass123!'
  privilege :user
  enabled false
end
