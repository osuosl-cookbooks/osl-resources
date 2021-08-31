control 'osl_systemd_unit_drop_in' do
  describe ini('/etc/systemd/system/testing.d/hash_override.conf') do
    its('Unit.Key1') { should eq 'Val1' }
    its('Unit.Key2') { should eq 'Val2' }
    its('Service.Key3') { should eq 'Val3' }
  end
  describe ini('/etc/systemd/system/testing.d/string_override.conf') do
    its('Unit.Key4') { should eq 'Val4' }
    its('Unit.Key5') { should eq 'Val5' }
    its('Install.Key6') { should eq 'Val6' }
  end
  describe ini('/etc/systemd/nonstandard/testing.d/nonstandard.conf') do
    its('Unit.Key1') { should eq 'Val1' }
    its('Unit.Key2') { should eq 'Val2' }
    its('Service.Key3') { should eq 'Val3' }
  end
end
