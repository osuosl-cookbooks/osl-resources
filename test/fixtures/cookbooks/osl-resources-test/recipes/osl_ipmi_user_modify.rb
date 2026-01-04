# Test modify action edge cases

# First create a user with ADMINISTRATOR privilege
osl_ipmi_user 'testmodify' do
  password 'InitialPass123!'
  privilege :administrator
end

# Modify to change privilege to OPERATOR
osl_ipmi_user 'testmodify' do
  privilege :operator
  action :modify
end

# Create a user that will be disabled via modify
osl_ipmi_user 'testdisable' do
  password 'DisableMe123!'
  privilege :user
end

# Disable the user via modify action
osl_ipmi_user 'testdisable' do
  enabled false
  action :modify
end

# Create a user that will have password changed
osl_ipmi_user 'testpassword' do
  password 'OldPassword123!'
  privilege :user
end

# Change password via modify action
osl_ipmi_user 'testpassword' do
  password 'NewPassword456!'
  action :modify
end
