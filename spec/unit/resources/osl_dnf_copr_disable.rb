require_relative '../../spec_helper'

describe 'osl-resources-test::osl_dnf_copr_disable' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.dup.merge(step_into: %w(osl_dnf_copr))).converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to install_package('dnf-plugins-core') }

      it do
        is_expected.to run_execute('dnf copr enable rapier1/hpnssh')
          .with(command: 'dnf -y copr enable rapier1/hpnssh')
      end

      it do
        is_expected.to run_execute('dnf copr remove rapier1/hpnssh')
          .with(command: 'dnf -y copr remove rapier1/hpnssh')
      end
    end
  end
end
