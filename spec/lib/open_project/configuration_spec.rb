#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe OpenProject::Configuration do
  describe '.load_config_from_file' do
    let(:config) { Hash.new }

    before do
      expect(File).to receive(:file?).with('file').and_return(true)
      expect(File).to receive(:read).and_return("
        default:

        test:
          somesetting: foo
      ")

      OpenProject::Configuration.send(:load_config_from_file, 'file', 'test', config)
    end

    it 'should merge the config from the file into the given config hash' do
      expect(config['somesetting']).to eq('foo')
    end
  end

  describe '.load_env_from_config' do
    describe 'with a default setting' do
      let(:config) {
        OpenProject::Configuration.send(:load_env_from_config, {
                                          'default' => { 'somesetting' => 'foo' },
                                          'test' => {},
                                          'someother' => { 'somesetting' => 'bar' }
                                        }, 'test')}

      it 'should load a default setting' do
        expect(config['somesetting']).to eq('foo')
      end
    end

    describe 'with an environment-specific setting' do
      let(:config) {
        OpenProject::Configuration.send(:load_env_from_config, {
                                          'default' => {},
                                          'test' => { 'somesetting' => 'foo' }
                                        }, 'test')}

      it 'should load a setting' do
        expect(config['somesetting']).to eq('foo')
      end
    end

    describe 'with a default and an overriding environment-specific setting' do
      let(:config) {
        OpenProject::Configuration.send(:load_env_from_config, {
                                          'default' => { 'somesetting' => 'foo' },
                                          'test' => { 'somesetting' => 'bar' }
                                        }, 'test')}

      it 'should load the overriding value' do
        expect(config['somesetting']).to eq('bar')
      end
    end
  end

  describe '.load_overrides_from_environment_variables' do
    let(:config) {
      {
        'somesetting' => 'foo',
        'nested' => {
          'key' => 'value',
          'deeply_nested' => {
            'key' => nil
          }
        }
      }
    }

    let(:env_vars) {
      {
        'SOMESETTING' => 'bar',
        'OPTEST_NESTED_KEY' => 'baz',
        'OPTEST_NESTED_DEEPLY__NESTED_KEY' => '42'
      }
    }

    before do
      stub_const('OpenProject::Configuration::ENV_PREFIX', 'OPTEST')

      OpenProject::Configuration.send :override_config!, config, env_vars
    end

    it 'should override the previous setting value' do
      expect(config['somesetting']).to eq('bar')
    end

    it 'should override a nested value' do
      expect(config['nested']['key']).to eq('baz')
    end

    it 'should override values nested several levels deep' do
      expect(config['nested']['deeply_nested']['key']).to eq('42')
    end
  end

  describe '.with' do
    before do
      expect(OpenProject::Configuration).to receive(:load_config_from_file) do |_filename, _env, config|
        config.merge!('somesetting' => 'foo')
      end
      OpenProject::Configuration.load(env: 'test')
    end

    it 'should return the overriden the setting within the block' do
      expect(OpenProject::Configuration['somesetting']).to eq('foo')

      OpenProject::Configuration.with 'somesetting' => 'bar' do
        expect(OpenProject::Configuration['somesetting']).to eq('bar')
      end

      expect(OpenProject::Configuration['somesetting']).to eq('foo')
    end
  end

  describe '.convert_old_email_settings' do
    let(:settings) {
      {
        'email_delivery' => {
          'delivery_method' => :smtp,
          'perform_deliveries' => true,
          'smtp_settings' => {
            'address' => 'smtp.example.net',
            'port' => 25,
            'domain' => 'example.net'
          } } }
    }

    context 'with delivery_method' do
      before do
        OpenProject::Configuration.send(:convert_old_email_settings, settings,
                                        disable_deprecation_message: true)
      end

      it 'should adopt the delivery method' do
        expect(settings['email_delivery_method']).to eq(:smtp)
      end

      it 'should convert smtp settings' do
        expect(settings['smtp_address']).to eq('smtp.example.net')
        expect(settings['smtp_port']).to eq(25)
        expect(settings['smtp_domain']).to eq('example.net')
      end
    end

    context 'without delivery_method' do
      before do
        settings['email_delivery'].delete('delivery_method')
        OpenProject::Configuration.send(:convert_old_email_settings, settings,
                                        disable_deprecation_message: true)
      end

      it 'should convert smtp settings' do
        expect(settings['smtp_address']).to eq('smtp.example.net')
        expect(settings['smtp_port']).to eq(25)
        expect(settings['smtp_domain']).to eq('example.net')
      end
    end
  end

  describe '.configure_action_mailer' do
    let(:action_mailer) { double('ActionMailer::Base') }
    let(:config) {
      { 'email_delivery_method' => 'smtp',
        'smtp_address' => 'smtp.example.net',
        'smtp_port' => '25' }
    }

    before do
      stub_const('ActionMailer::Base', action_mailer)
    end

    it 'should enable deliveries and configure ActionMailer smtp delivery' do
      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      expect(action_mailer).to receive(:smtp_settings=).with(address: 'smtp.example.net',
                                                             port: '25')
      OpenProject::Configuration.send(:configure_action_mailer, config)
    end
  end

  describe '.configure_cache' do
    let(:application_config) { Rails::Application::Configuration.new }

    after do
      # reload configuration to isolate specs
      OpenProject::Configuration.load
    end

    context 'with cache store already set' do
      before do
        application_config.cache_store = 'foo'
      end

      context 'with additional cache store configuration' do
        before do
          OpenProject::Configuration['rails_cache_store'] = 'bar'
        end

        it 'changes the cache store' do
          OpenProject::Configuration.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq([:bar])
        end
      end

      context 'without additional cache store configuration' do
        before do
          OpenProject::Configuration['rails_cache_store'] = nil
        end

        it 'does not change the cache store' do
          OpenProject::Configuration.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq('foo')
        end
      end
    end

    context 'without cache store already set' do
      before do
        application_config.cache_store = nil
      end

      context 'with additional cache store configuration' do
        before do
          OpenProject::Configuration['rails_cache_store'] = 'bar'
        end

        it 'changes the cache store' do
          OpenProject::Configuration.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq([:bar])
        end
      end

      context 'without additional cache store configuration' do
        before do
          OpenProject::Configuration['rails_cache_store'] = nil
        end
        it 'defaults the cache store to :file_store' do
          OpenProject::Configuration.send(:configure_cache, application_config)
          expect(application_config.cache_store.first).to eq(:file_store)
        end
      end
    end
  end
end
