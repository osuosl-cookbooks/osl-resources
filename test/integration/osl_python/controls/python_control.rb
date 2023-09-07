control 'osl_python' do
  title 'Verify python is configured'

  os_family = os.family
  os_release = os.release.to_i

  case os_family
  when 'redhat'
    case os_release
    when 8
      packages = %w(
        python2
        python2-devel
        python2-pip
        python2-setuptools
        python2-virtualenv
        python3-pip
        python3-setuptools
        python3-virtualenv
        python36
        python36-devel
      )
    when 7
      packages = %w(
        python
        python2-pip
        python3
        python3-devel
        python3-pip
        python3-setuptools
        python-devel
        python-setuptools
        python-virtualenv
      )
    end
  when 'debian'
    case os_release
    when 11
      packages = %w(
        python3
        python3-dev
        python3-pip
        python3-setuptools
        python3-virtualenv
        python3-wheel
        python2-dev
        python-pip-whl
        python-setuptools
        virtualenv
        python-wheel-common
      )
    end
  end

  packages.each do |pkg|
    describe package pkg do
      it { should be_installed }
    end
  end
end
