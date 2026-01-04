# Integration tests for osl_ipmi_user delete action

control 'osl_ipmi_user_delete' do
  title 'IPMI User Deletion'

  # Check for IPMI device
  ipmi_available = file('/dev/ipmi0').exist? ||
                   file('/dev/ipmi/0').exist? ||
                   file('/dev/ipmidev/0').exist?

  if ipmi_available
    # Check that ipmitool package is installed
    describe package('ipmitool') do
      it { should be_installed }
    end

    # Check that testadmin user still exists
    # link=on is set for enabled users, so Link Auth = true
    describe command('ipmitool user list 1') do
      its('stdout') { should match(/testadmin/) }
      its('stdout') { should match(/testadmin\s+true\s+true\s+true\s+ADMINISTRATOR/) }
    end

    # Check that testoperator user was deleted (disabled and/or cleared)
    # After deletion, the user should either not appear or be disabled
    describe command('ipmitool user list 1') do
      its('stdout') { should_not match(/testoperator\s+true\s+true\s+true/) }
    end

    # Check that testadmin password hash still exists (user was not deleted)
    describe file('/var/lib/osl-ipmi/testadmin.pwdhash') do
      it { should exist }
    end

    # Check that testoperator password hash was removed when user was deleted
    describe file('/var/lib/osl-ipmi/testoperator.pwdhash') do
      it { should_not exist }
    end
  else
    describe 'IPMI device not available' do
      it 'should skip IPMI configuration gracefully' do
        expect(true).to eq(true)
      end
    end
  end
end
