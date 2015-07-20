#
# Cookbook Name:: unbound
# Spec:: default
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'

describe 'unbound::default' do
  context 'with default attributes' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.5')
        .converge(described_recipe)
    end
    subject { chef_run }

    it { is_expected.not_to create_template(%r{^/etc/unbound/conf\.d/stub_.*\.conf$}) }
    it { is_expected.not_to create_template(%r{^/etc/unbound/conf\.d/forward_.*\.conf$}) }

    it { is_expected.to create_directory('/var/log/unbound') }

    it { is_expected.to start_service('unbound') }
  end

  context 'with non-default attributes' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.5') do |node|
        node.set['unbound']['log_dir'] = '/var/log/dns'
        node.set['unbound']['config']['include'] = '/etc/unbound/other.d/*.conf'
        node.set['unbound']['config']['server'] = {
          'logfile'         => '/var/log/dns/unbound.log',
          'interface'       => '0.0.0.0',
          'access-control'  => [
            '10.0.0.0/24 allow',
            '172.31.0.0/24 allow'
          ]
        }
        node.set['unbound']['stub_zones'] = [
          {
            'name'       => 'mystub.example.com',
            'stub-addr'  => '192.0.2.68',
            'stub-prime' => 'no'
          },
          {
            'name'       => 'mystub2.example.com',
            'stub-addr'  => '192.0.3.68',
            'stub-prime' => 'yes'
          }
        ]

        node.set['unbound']['forward_zones'] = [
          {
            'name'         => 'myforward.example.com',
            'forward-addr' => '192.0.5.68'
          },
          {
            'name'         => 'myforward2.example.com',
            'forward-host' => 'example.com'
          }
        ]
      end.converge(described_recipe)
    end
    subject { chef_run }

    it { is_expected.to create_template('/etc/unbound/conf.d/stub_mystub.example.com.conf') }
    it { is_expected.to create_template('/etc/unbound/conf.d/stub_mystub2.example.com.conf') }
    it { is_expected.to create_template('/etc/unbound/conf.d/forward_myforward.example.com.conf') }
    it { is_expected.to create_template('/etc/unbound/conf.d/forward_myforward2.example.com.conf') }

    it { is_expected.to create_directory('/var/log/dns') }

    [
      'stub-zone:',
      'name: "mystub.example.com"',
      'stub-addr: 192.0.2.68',
      'stub-prime: no'
    ].each do |content|
      it do
        is_expected.to(
          render_file('/etc/unbound/conf.d/stub_mystub.example.com.conf')
            .with_content(content)
        )
      end
    end

    [
      'forward-zone:',
      'name: "myforward.example.com"',
      'forward-addr: 192.0.5.68'
    ].each do |content|
      it do
        is_expected.to(
          render_file('/etc/unbound/conf.d/forward_myforward.example.com.conf')
            .with_content(content)
        )
      end
    end
  end
end
