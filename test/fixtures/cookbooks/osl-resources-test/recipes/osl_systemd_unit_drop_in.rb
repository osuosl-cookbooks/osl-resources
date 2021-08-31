osl_systemd_unit_drop_in 'hash_override' do
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
end

osl_systemd_unit_drop_in 'string_override' do
  unit_name 'testing'
  content <<~EOU
  [Unit]
  Key4 = Val4
  Key5 = Val5

  [Install]
  Key6 = Val6
EOU
end

osl_systemd_unit_drop_in 'nonstandard' do
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
  instance 'nonstandard'
end
