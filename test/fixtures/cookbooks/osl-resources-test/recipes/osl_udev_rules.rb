osl_udev_rules 'rename eth0' do
  rule 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", KERNELS=="0000:00:03.0", ATTR{type}=="1", KERNEL=="*", NAME="net0"'
end
