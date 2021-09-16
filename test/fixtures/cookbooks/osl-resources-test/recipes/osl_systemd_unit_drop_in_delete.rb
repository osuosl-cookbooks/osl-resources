osl_systemd_unit_drop_in 'to_delete' do
  unit_name 'testing'
  content({
    'Unit' => {
      'Key1' => 'Val1',
      'Key2' => 'Val2',
    },
    'Service' => {
      'Key3' => 'Val3',
    },
  })
  action :create
end

osl_systemd_unit_drop_in 'to_delete' do
  unit_name 'testing'
  action :delete
end
