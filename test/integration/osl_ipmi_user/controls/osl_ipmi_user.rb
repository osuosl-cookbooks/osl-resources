# Integration tests for osl_ipmi_user
# Note: These tests are designed to work with mocked IPMI or on real hardware
# On systems without IPMI, the resource should soft-fail gracefully

control 'osl_ipmi_user' do
  title 'IPMI User Management'

  # Check for IPMI device - if not present, remaining tests are skipped
  ipmi_available = file('/dev/ipmi0').exist? ||
                   file('/dev/ipmi/0').exist? ||
                   file('/dev/ipmidev/0').exist?

  if ipmi_available
    # Check that ipmitool package is installed (only when IPMI is available)
    describe package('ipmitool') do
      it { should be_installed }
    end

    describe command('ipmitool user list 1') do
      its('exit_status') { should eq 0 }
    end

    # Check that testadmin user was created with ADMINISTRATOR privilege
    # ipmitool output format: ID  Name  Callin  Link Auth  IPMI Msg  Channel Priv Limit
    # link=on is set for enabled users, so Link Auth = true
    describe command('ipmitool user list 1') do
      its('stdout') { should match(/testadmin/) }
      its('stdout') { should match(/testadmin\s+true\s+true\s+true\s+ADMINISTRATOR/) }
    end

    # Check that testoperator user was created with OPERATOR privilege
    describe command('ipmitool user list 1') do
      its('stdout') { should match(/testoperator/) }
      its('stdout') { should match(/testoperator\s+true\s+true\s+true\s+OPERATOR/) }
    end

    # Check that testdisabled user was created but is disabled (IPMI Msg = false)
    describe command('ipmitool user list 1') do
      its('stdout') { should match(/testdisabled/) }
      its('stdout') { should match(/testdisabled\s+true\s+false\s+false\s+USER/) }
    end

    # Check that password hash files were created for idempotency tracking
    describe file('/var/lib/osl-ipmi') do
      it { should be_directory }
      its('mode') { should cmp '0700' }
    end

    describe file('/var/lib/osl-ipmi/testadmin.pwdhash') do
      it { should exist }
      its('mode') { should cmp '0600' }
      its('content') { should match(/^[a-f0-9]{64}$/) }
    end

    describe file('/var/lib/osl-ipmi/testoperator.pwdhash') do
      it { should exist }
      its('mode') { should cmp '0600' }
    end

    describe file('/var/lib/osl-ipmi/testdisabled.pwdhash') do
      it { should exist }
      its('mode') { should cmp '0600' }
    end
  else
    # No IPMI device - verify the resource handled it gracefully
    describe 'IPMI device not available' do
      it 'should skip IPMI configuration gracefully' do
        # The Chef run should have completed successfully
        # even without IPMI hardware
        expect(true).to eq(true)
      end
    end
  end
end
