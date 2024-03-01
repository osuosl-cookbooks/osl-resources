control 'osl_udev_rules' do
  describe file '/etc/udev/rules.d/99-chef.rules' do
    its('content') { should match /SUBSYSTEM=="net", ACTION=="add", DRIVERS=="\?\*", KERNELS=="0000:00:03\.0", ATTR{type}=="1", KERNEL=="\*", NAME="net0"/ }
  end
end
