resource_name :osl_opensearch_user
provides :osl_opensearch_user
default_action :create
unified_mode true

property :username, String, name_property: true
property :password, String, sensitive: true, required: true
property :backend_roles, Array

action :create do
  user = osl_opensearch_username(new_resource.username)
  if !user
    converge_by("creating user #{new_resource.username}") do
      osl_opensearch_client.security.create_user(
        username: new_resource.username,
        body: {
          password: new_resource.password,
          backend_roles: new_resource.backend_roles,
        }
      )
    end
  elsif user[new_resource.username]['backend_roles'] != new_resource.backend_roles
    converge_by("updating user #{new_resource.username}") do
      osl_opensearch_client.security.patch_user(
        username: new_resource.username,
        body: {
          backend_roles: new_resource.backend_roles,
        }
      )
    end
  end
end
