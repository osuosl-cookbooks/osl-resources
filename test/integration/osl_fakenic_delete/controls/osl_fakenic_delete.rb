control 'osl_fakenic_delete' do
  describe command('ip -details link show dev dummy1') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /UP/ }
    its('stdout') { should match /^\s+dummy\s/ }
  end

  describe command('ip -details link show dev dummy2') do
    its('exit_status') { should eq 1 }
  end
end
