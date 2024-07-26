if debian?
  apt_update

  kernel_pkg = platform?('debian') ? 'linux-image-amd64' : 'linux-image-virtual'

  package kernel_pkg do
    action :upgrade
    notifies :reboot_now, 'reboot[upgrade kernel]', :immediately
  end

  reboot 'upgrade kernel'
end

osl_virtualbox '7.0'
