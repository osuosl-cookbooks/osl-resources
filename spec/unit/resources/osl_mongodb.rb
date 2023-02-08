require_relative '../../spec_helper'

describe 'osl_mongodb' do
  platform 'rhel'
  cached(:subject) { chef_run }
  step_into :osl_mongodb

  recipe do
    osl_mongodb '6.0'
  end

  it do
    is_expected.to create_yum_repository('mongodb-org-6.0')
      .with(
        baseurl: 'https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/6.0/$basearch/',
        repo_gpgcheck: true,
        gpgcheck: true,
        gpgkey: 'https://www.mongodb.org/static/pgp/server-6.0.asc'
      )
  end

  it { is_expected.to install_package('mongodb-org') }
  it { is_expected.to include_recipe('osl-selinux') }

  it do
    is_expected.to create_template('/etc/mongod.conf')
      .with(
        source: 'mongod.erb',
        cookbook: 'osl-resources',
        owner: 'mongod',
        group: 'mongod',
        mode: '0644',
        variables: {
          data_dir: '/var/lib/mongo',
          log_dest: 'file',
          log_path: '/var/log/mongodb/mongod.log',
          port: 80,
          bind_ip: '127.0.0.1',
          max_connections: 51200,
        }
      )
  end

  it { is_expected.to enable_service('mongodb') }
  it { is_expected.to start_service('mongodb') }

  it do
    is_expected.to create_directory('/var/lib/mongo')
      .with(
        owner: mongod,
        group: mongod
      )
  end
  it do
    is_expected.to create_file('/var/log/mongodb/mongod.log')
      .with(
        owner: mongod,
        group: mongod
      )
  end
end
