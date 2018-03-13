#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
    let(:file_contents) {
      <<-EOS
      default:

        test:
        somesetting: foo
      EOS
    }
    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with('configfilename').and_return(file_contents)
      allow(File).to receive(:file?).with('configfilename').and_return(true)

      OpenProject::Configuration.load(file: 'configfilename')
    end

    it 'should merge the config from the file into the given config hash' do
      expect(OpenProject::Configuration['somesetting']).to eq('foo')
      expect(OpenProject::Configuration[:somesetting]).to eq('foo')
      expect(OpenProject::Configuration.somesetting).to eq('foo')
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
        'someemptysetting' => nil,
        'nil' => 'foobar',
        'str_empty' => 'foobar',
        'somesetting' => 'foo',
        'some_list_entry' => nil,
        'nested' => {
          'key' => 'value',
          'hash' => 'somethingelse',
          'deeply_nested' => {
            'key' => nil
          }
        },
        'foo' => {
          'bar' => {
            'hash_with_symbols': 1234
          }
        }
      }
    }

    let(:env_vars) {
      {
        'SOMEEMPTYSETTING' => '',
        'SOMESETTING' => 'bar',
        'NIL' => '!!null',
        'STR_EMPTY' => '!!str',
        'OPTEST_SOME__LIST__ENTRY' => '[foo, bar , xyz, whut wat]',
        'OPTEST_NESTED_KEY' => 'baz',
        'OPTEST_NESTED_DEEPLY__NESTED_KEY' => '42',
        'OPTEST_NESTED_HASH' => '{ foo: bar, xyz: bla }',
        'OPTEST_FOO_BAR_HASH__WITH__SYMBOLS' => '{ foo: !ruby/symbol foobar }'
      }
    }

    before do
      stub_const('OpenProject::Configuration::ENV_PREFIX', 'OPTEST')

      OpenProject::Configuration.send :override_config!, config, env_vars
    end

    it 'should not parse the empty value' do
      expect(config['someemptysetting']).to eq('')
    end

    it 'should parse the null identifier' do
      expect(config['nil']).to be_nil
    end

    it 'should parse the empty string' do
      expect(config['str_empty']).to eq('')
    end

    it 'should override the previous setting value' do
      expect(config['somesetting']).to eq('bar')
    end

    it 'should override a nested value' do
      expect(config['nested']['key']).to eq('baz')
    end

    it 'should override values nested several levels deep' do
      expect(config['nested']['deeply_nested']['key']).to eq(42)
    end

    it 'should parse simple comma-separated lists' do
      expect(config['some_list_entry']).to eq(['foo', 'bar', 'xyz', 'whut wat'])
    end

    it 'should parse simple hashes' do
      expect(config['nested']['hash']).to eq('foo' => 'bar', 'xyz' => 'bla')
    end

    it 'should parse hashes with symbols and non-string values' do
      expect(config['foo']['bar']['hash_with_symbols']).to eq('foo' => :foobar)
      expect(config['foo']['bar']['hash_with_symbols'][:foo]).to eq(:foobar)
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

  describe '.migrate_mailer_configuration!' do
    after do
      # reset this setting value
      Setting[:email_delivery_method] = nil
      # reload configuration to isolate specs
      OpenProject::Configuration.load
    end

    it 'does nothing if no legacy configuration given' do
      OpenProject::Configuration['email_delivery_method'] = nil
      expect(Setting).to_not receive(:email_delivery_method=)
      expect(OpenProject::Configuration.migrate_mailer_configuration!).to eq(true)
    end

    it 'does nothing if email_delivery_configuration forced to legacy' do
      OpenProject::Configuration['email_delivery_configuration'] = 'legacy'
      expect(Setting).to_not receive(:email_delivery_method=)
      expect(OpenProject::Configuration.migrate_mailer_configuration!).to eq(true)
    end

    it 'does nothing if setting already set' do
      OpenProject::Configuration['email_delivery_method'] = :sendmail
      Setting.email_delivery_method = :sendmail
      expect(Setting).to_not receive(:email_delivery_method=)
      expect(OpenProject::Configuration.migrate_mailer_configuration!).to eq(true)
    end

    it 'migrates the existing configuration to the settings table' do
      OpenProject::Configuration['email_delivery_method'] = :smtp
      OpenProject::Configuration['smtp_password'] = 'p4ssw0rd'
      OpenProject::Configuration['smtp_address'] = 'smtp.example.com'
      OpenProject::Configuration['smtp_port'] = 587
      OpenProject::Configuration['smtp_user_name'] = 'username'
      OpenProject::Configuration['smtp_enable_starttls_auto'] = true

      expect(OpenProject::Configuration.migrate_mailer_configuration!).to eq(true)
      expect(Setting.email_delivery_method).to eq(:smtp)
      expect(Setting.smtp_password).to eq('p4ssw0rd')
      expect(Setting.smtp_address).to eq('smtp.example.com')
      expect(Setting.smtp_port).to eq(587)
      expect(Setting.smtp_user_name).to eq('username')
      expect(Setting.smtp_enable_starttls_auto?).to eq(true)
    end
  end

  describe '.reload_mailer_configuration!' do
    let(:action_mailer) { double('ActionMailer::Base', smtp_settings: {}) }

    before do
      stub_const('ActionMailer::Base', action_mailer)
    end

    after do
      # reload configuration to isolate specs
      OpenProject::Configuration.load
    end

    it 'uses the legacy method to configure email settings' do
      OpenProject::Configuration['email_delivery_configuration'] = 'legacy'
      expect(OpenProject::Configuration).to receive(:configure_legacy_action_mailer)
      OpenProject::Configuration.reload_mailer_configuration!
    end

    it 'allows settings smtp_authentication to none' do
      Setting.email_delivery_method = :smtp
      Setting.smtp_authentication = :none
      Setting.smtp_password = 'old'
      Setting.smtp_address = 'smtp.example.com'
      Setting.smtp_domain = 'example.com'
      Setting.smtp_port = 25
      Setting.smtp_user_name = 'username'
      Setting.smtp_enable_starttls_auto = 1

      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      OpenProject::Configuration.reload_mailer_configuration!
      expect(action_mailer.smtp_settings[:smtp_authentication]).to be_nil
      expect(action_mailer.smtp_settings).to eq(address: 'smtp.example.com',
                                                port: 25,
                                                domain: 'example.com',
                                                enable_starttls_auto: true)
    end

    it 'correctly sets the action mailer configuration based on the settings' do
      Setting.email_delivery_method = :smtp
      Setting.smtp_password = 'p4ssw0rd'
      Setting.smtp_address = 'smtp.example.com'
      Setting.smtp_domain = 'example.com'
      Setting.smtp_port = 587
      Setting.smtp_user_name = 'username'
      Setting.smtp_enable_starttls_auto = 1

      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      OpenProject::Configuration.reload_mailer_configuration!
      expect(action_mailer.smtp_settings).to eq(address: 'smtp.example.com',
                                                port: 587,
                                                domain: 'example.com',
                                                authentication: 'plain',
                                                user_name: 'username',
                                                password: 'p4ssw0rd',
                                                enable_starttls_auto: true)
    end
  end

  describe '.configure_legacy_action_mailer' do
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
      OpenProject::Configuration.send(:configure_legacy_action_mailer, config)
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
