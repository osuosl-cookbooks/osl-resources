require_relative '../../spec_helper'

describe 'osl_mongodb' do
  platform 'rhel'
  cached(:subject) { chef_run }
  step_into :osl_mongodb

  recipe do
    osl_mongodb '6.0'
  end

  it { is_expected.to include_recipe('osl-selinux') }

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

  context 'version 4.4' do
    recipe do
      osl_mongodb '4.4'
    end

    it do
      is_expected.to create_yum_repository('mongodb-org-4.4')
        .with(
          baseurl: 'https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.4/$basearch/',
          repo_gpgcheck: true,
          gpgcheck: true,
          gpgkey: 'https://www.mongodb.org/static/pgp/server-4.4.asc'
        )
    end
  end

  context 'install_selinux_policy false' do
    recipe do
      osl_mongodb '6.0' do
        install_selinux_policy false
      end
    end

    it { is_expected.to_not include_recipe('osl-selinux') }
  end

  context 'data_dir /var/lib/mongo2' do
    recipe do
      osl_mongodb '6.0' do
        data_dir '/var/lib/mongo2'
      end
    end

    it do
      is_expected.to create_template('/etc/mongod.conf')
        .with(
          source: 'mongod.erb',
          cookbook: 'osl-resources',
          owner: 'mongod',
          group: 'mongod',
          mode: '0644',
          variables: {
            data_dir: '/var/lib/mongo2',
            log_dest: 'file',
            log_path: '/var/log/mongodb/mongod.log',
            port: 80,
            bind_ip: '127.0.0.1',
            max_connections: 51200,
          }
        )
    end

    it do
      is_expected.to_not create_directory('var/lib/mongo')
      is_expected.to create_directory('/var/lib/mongo2')
        .with(
          owner: mongod,
          group: mongod
        )
    end
  end

  context 'log_dest syslog' do
    recipe do
      osl_mongodb '6.0' do
        log_dest 'syslog'
      end
    end

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
            log_dest: 'syslog',
            port: 80,
            bind_ip: '127.0.0.1',
            max_connections: 51200,
          }
        )
    end

    it { is_expected.to_not create_file('/var/log/mongodb/mongod.log') }
  end
end
