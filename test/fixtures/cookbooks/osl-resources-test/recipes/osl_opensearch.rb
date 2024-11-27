osl_opensearch 'default' do
  internal_users(
    'admin' => {
      # password is 'admin'
      'hash' => '$2y$12$.JAE.6kn0YuaTMsfH7dZRu7bKHQ3KpvPTjCx85sEe7Nvh..Iisa6q',
      'reserved' =>  true,
      'backend_roles' => %w(admin),
      'description' => 'admin',
    }
  )
end
