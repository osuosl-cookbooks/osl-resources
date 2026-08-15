# persist defaults to true, so this suite can be verified again after a manual
# reboot. It is the only fakenic coverage that runs on Debian and Ubuntu as
# well as AlmaLinux, so it is where the unit gets exercised cross-platform.
osl_fakenic 'dummy1'

osl_fakenic 'dummy2' do
  ip4 '192.168.0.1/24'
  ip6 'fe80::1/64'
  mac_address '00:1a:4b:a6:a7:c4'
  multicast true
end
