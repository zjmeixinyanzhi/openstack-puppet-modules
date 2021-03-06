require 'spec_helper'

describe 'ceilometer::client' do

  shared_examples_for 'ceilometer client' do

    it { is_expected.to contain_class('ceilometer::params') }

    it 'installs ceilometer client package' do
      is_expected.to contain_package('python-ceilometerclient').with(
        :ensure => 'present',
        :name   => platform_params[:client_package_name],
        :tag    => 'openstack',
      )
    end
  end

  context 'on Debian platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'Debian' })
    end

    let :platform_params do
      { :client_package_name => 'python-ceilometerclient' }
    end

    it_configures 'ceilometer client'
  end

  context 'on RedHat platforms' do
    let :facts do
      @default_facts.merge({ :osfamily => 'RedHat' })
    end

    let :platform_params do
      { :client_package_name => 'python-ceilometerclient' }
    end

    it_configures 'ceilometer client'
  end
end
