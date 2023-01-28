require 'spec_helper'

describe 'osl_packagecloud_repo' do
  platform 'rhel'
  cached(:subject) { chef_run }
  step_into :osl_mongodb

  it do
    is_expected.to create_yum_repository('mongodb-org-6.0')
      .with(
        baseurl: 'https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/6.0/x86_64/',
        repo_gpgcheck: true,
        gpgcheck: true,
        gpgkey: 'https://www.mongodb.org/static/pgp/server-6.0.asc'
      )
  end
  it { is_expected.to install_package('mongodb-org') }

  it do
    is_expected.to create_template('/etc/mongod.conf')
      .with(
        source: 'mongod.erb'
      )
  end

  it { is_expected.to enable_service('mongodb') }
  it { is_expected.to start_service('mongodb') }
end
