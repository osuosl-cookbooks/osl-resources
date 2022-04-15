if debian?
  apt_update

  package 'linux-image-amd64' do
    action :upgrade
    notifies :reboot_now, 'reboot[upgrade kernel]', :immediately
  end

  reboot 'upgrade kernel'
end

osl_virtualbox '6.1'
