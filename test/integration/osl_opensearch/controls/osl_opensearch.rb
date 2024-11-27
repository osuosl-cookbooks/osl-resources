control 'osl_opensearch' do
  describe service 'opensearch' do
    it { should be_enabled }
    it { should be_running }
  end

  describe port 9200 do
    it { should be_listening }
  end

  describe json(
    content: http(
      'https://127.0.0.1:9200',
      auth: {
        user: 'admin',
        pass: 'admin',
      },
      ssl_verify: false
    ).body
  ) do
    its('name') { should cmp 'opensearch-node1.osuosl.org' }
    its('cluster_name') { should cmp 'default' }
  end
end
