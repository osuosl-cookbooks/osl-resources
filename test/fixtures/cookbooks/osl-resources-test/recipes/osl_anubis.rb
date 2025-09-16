osl_anubis 'default' do
  custom_bots [
    {
      'name' => 'static-assets',
      'path_regex' => '^/assets/.*$',
      'action' => 'ALLOW',
    },
  ]
  extra_config(
    'store' => {
      'backend' => 'memory',
      'parameters' => {},
    }
  )
end
