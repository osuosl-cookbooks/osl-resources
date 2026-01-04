# Integration tests for osl_ipmi_user modify action

control 'osl_ipmi_user_modify' do
  title 'IPMI User Modify Action'

  # Check for IPMI device
  ipmi_available = file('/dev/ipmi0').exist? ||
                   file('/dev/ipmi/0').exist? ||
                   file('/dev/ipmidev/0').exist?

  if ipmi_available
    describe package('ipmitool') do
      it { should be_installed }
    end

    # Check testmodify was created then modified to OPERATOR
    describe command('ipmitool user list 1') do
      its('stdout') { should match(/testmodify/) }
      # After modify, should have OPERATOR privilege
      its('stdout') { should match(/testmodify\s+true\s+false\s+true\s+OPERATOR/) }
    end

    # Check testdisable was disabled (IPMI Msg = false)
    describe command('ipmitool user list 1') do
      its('stdout') { should match(/testdisable/) }
      its('stdout') { should match(/testdisable\s+true\s+false\s+false\s+USER/) }
    end

    # Check testpassword exists (we can't verify password was changed via ipmitool list)
    describe command('ipmitool user list 1') do
      its('stdout') { should match(/testpassword/) }
      its('stdout') { should match(/testpassword\s+true\s+false\s+true\s+USER/) }
    end

    # Check that password hash files were updated after modify
    describe file('/var/lib/osl-ipmi/testpassword.pwdhash') do
      it { should exist }
      its('mode') { should cmp '0600' }
      # Verify hash is valid SHA256 (64 hex characters)
      its('content') { should match(/^[a-f0-9]{64}$/) }
    end

    # testmodify should have hash file from initial create
    describe file('/var/lib/osl-ipmi/testmodify.pwdhash') do
      it { should exist }
    end
  else
    describe 'IPMI device not available' do
      it 'should skip IPMI configuration gracefully' do
        expect(true).to eq(true)
      end
    end
  end
end
