control 'osl_systemd_unit_drop_in_delete' do
  describe file('/etc/systemd/system/testing.d/to_delete.conf') do
    it { should_not exist }
  end
end
