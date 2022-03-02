#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe OpenProject::Configuration do
  describe '.load_config_from_file' do
    let(:file_contents) do
      <<-CONTENT
      default:

        test:
        somesetting: foo
      CONTENT
    end

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with('configfilename').and_return(file_contents)
      allow(File).to receive(:file?).with('configfilename').and_return(true)

      described_class.load(file: 'configfilename')
    end

    it 'merges the config from the file into the given config hash' do
      expect(described_class['somesetting']).to eq('foo')
      expect(described_class[:somesetting]).to eq('foo')
      expect(described_class.somesetting).to eq('foo')
    end

    context 'with deep nesting' do
      let(:file_contents) do
        <<-CONTENT
        default:
          web:
           timeout: 42
        CONTENT
      end

      it 'deepmerges the config from the file into the given config hash' do
        expect(described_class['web']['workers']).not_to be_nil
        expect(described_class['web']['timeout']).to eq(42)
      end
    end
  end

  describe '.load_env_from_config' do
    describe 'with a default setting' do
      let(:config) do
        described_class.send(:load_env_from_config, {
                               'default' => { 'somesetting' => 'foo' },
                               'test' => {},
                               'someother' => { 'somesetting' => 'bar' }
                             }, 'test')
      end

      it 'loads a default setting' do
        expect(config['somesetting']).to eq('foo')
      end
    end

    describe 'with an environment-specific setting' do
      let(:config) do
        described_class.send(:load_env_from_config, {
                               'default' => {},
                               'test' => { 'somesetting' => 'foo' }
                             }, 'test')
      end

      it 'loads a setting' do
        expect(config['somesetting']).to eq('foo')
      end
    end

    describe 'with a default and an overriding environment-specific setting' do
      let(:config) do
        described_class.send(:load_env_from_config, {
                               'default' => { 'somesetting' => 'foo' },
                               'test' => { 'somesetting' => 'bar' }
                             }, 'test')
      end

      it 'loads the overriding value' do
        expect(config['somesetting']).to eq('bar')
      end

      context 'with deep nesting' do
        let(:config) do
          described_class.send(:load_env_from_config, {
                                 'default' => { 'web' => {
                                   'overridensetting' => 'unseen!',
                                   'somesetting' => 'foo'
                                 } },
                                 'test' => { 'web' => {
                                   'overridensetting' => 'env wins',
                                   'someothersetting' => 'bar'
                                 } }
                               }, 'test')
        end

        it 'deepmerges configs together' do
          expect(config['web']['overridensetting']).to eq('env wins')
          expect(config['web']['somesetting']).to eq('foo')
          expect(config['web']['someothersetting']).to eq('bar')
        end
      end
    end
  end

  describe '.load_overrides_from_environment_variables' do
    let(:config) do
      {
        'someemptysetting' => nil,
        'nil' => 'foobar',
        'str_empty' => 'foobar',
        'somesetting' => 'foo',
        'invalid_yaml' => nil,
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
            hash_with_symbols: 1234
          }
        }
      }
    end

    let(:env_vars) do
      {
        'SOMEEMPTYSETTING' => '',
        'SOMESETTING' => 'bar',
        'NIL' => '!!null',
        'INVALID_YAML' => "'foo'! #234@@½%%%",
        'OPTEST_SOME__LIST__ENTRY' => '[foo, bar , xyz, whut wat]',
        'OPTEST_NESTED_KEY' => 'baz',
        'OPTEST_NESTED_DEEPLY__NESTED_KEY' => '42',
        'OPTEST_NESTED_HASH' => '{ foo: bar, xyz: bla }',
        'OPTEST_FOO_BAR_HASH__WITH__SYMBOLS' => '{ foo: !ruby/symbol foobar }'
      }
    end

    before do
      stub_const('OpenProject::Configuration::ENV_PREFIX', 'OPTEST')

      described_class.send :override_config!, config, env_vars
    end

    it 'returns the original string, not the invalid YAML one' do
      expect(config['invalid_yaml']).to eq env_vars['INVALID_YAML']
    end

    it 'does not parse the empty value' do
      expect(config['someemptysetting']).to eq('')
    end

    it 'parses the null identifier' do
      expect(config['nil']).to be_nil
    end

    it 'overrides the previous setting value' do
      expect(config['somesetting']).to eq('bar')
    end

    it 'overrides a nested value' do
      expect(config['nested']['key']).to eq('baz')
    end

    it 'overrides values nested several levels deep' do
      expect(config['nested']['deeply_nested']['key']).to eq(42)
    end

    it 'parses simple comma-separated lists' do
      expect(config['some_list_entry']).to eq(['foo', 'bar', 'xyz', 'whut wat'])
    end

    it 'parses simple hashes' do
      expect(config['nested']['hash']).to eq('foo' => 'bar', 'xyz' => 'bla')
    end

    it 'parses hashes with symbols and non-string values' do
      expect(config['foo']['bar']['hash_with_symbols']).to eq('foo' => :foobar)
      expect(config['foo']['bar']['hash_with_symbols'][:foo]).to eq(:foobar)
    end
  end

  describe '.with' do
    before do
      allow(described_class).to receive(:load_config_from_file) do |_filename, _env, config|
        config.merge!('somesetting' => 'foo')
      end
      described_class.load(env: 'test')
    end

    it 'returns the overridden the setting within the block' do
      expect(described_class['somesetting']).to eq('foo')

      described_class.with 'somesetting' => 'bar' do
        expect(described_class['somesetting']).to eq('bar')
      end

      expect(described_class['somesetting']).to eq('foo')
    end
  end

  describe '.convert_old_email_settings' do
    let(:settings) do
      {
        'email_delivery' => {
          'delivery_method' => :smtp,
          'perform_deliveries' => true,
          'smtp_settings' => {
            'address' => 'smtp.example.net',
            'port' => 25,
            'domain' => 'example.net'
          }
        }
      }
    end

    context 'with delivery_method' do
      before do
        described_class.send(:convert_old_email_settings, settings,
                             disable_deprecation_message: true)
      end

      it 'adopts the delivery method' do
        expect(settings['email_delivery_method']).to eq(:smtp)
      end

      it 'converts smtp settings' do
        expect(settings['smtp_address']).to eq('smtp.example.net')
        expect(settings['smtp_port']).to eq(25)
        expect(settings['smtp_domain']).to eq('example.net')
      end
    end

    context 'without delivery_method' do
      before do
        settings['email_delivery'].delete('delivery_method')
        described_class.send(:convert_old_email_settings, settings,
                             disable_deprecation_message: true)
      end

      it 'converts smtp settings' do
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
      described_class.load
      # clear settings cache to isolate specs
      Setting.clear_cache
    end

    it 'does nothing if no legacy configuration given' do
      described_class['email_delivery_method'] = nil
      expect(Setting).not_to receive(:email_delivery_method=)
      expect(described_class.migrate_mailer_configuration!).to eq(true)
    end

    it 'does nothing if email_delivery_configuration forced to legacy' do
      described_class['email_delivery_configuration'] = 'legacy'
      expect(Setting).not_to receive(:email_delivery_method=)
      expect(described_class.migrate_mailer_configuration!).to eq(true)
    end

    it 'does nothing if setting already set' do
      described_class['email_delivery_method'] = :sendmail
      Setting.email_delivery_method = :sendmail
      expect(Setting).not_to receive(:email_delivery_method=)
      expect(described_class.migrate_mailer_configuration!).to eq(true)
    end

    it 'migrates the existing configuration to the settings table' do
      described_class['email_delivery_method'] = :smtp
      described_class['smtp_password'] = 'p4ssw0rd'
      described_class['smtp_address'] = 'smtp.example.com'
      described_class['smtp_port'] = 587
      described_class['smtp_user_name'] = 'username'
      described_class['smtp_enable_starttls_auto'] = true
      described_class['smtp_ssl'] = true

      expect(described_class.migrate_mailer_configuration!).to eq(true)
      expect(Setting.email_delivery_method).to eq(:smtp)
      expect(Setting.smtp_password).to eq('p4ssw0rd')
      expect(Setting.smtp_address).to eq('smtp.example.com')
      expect(Setting.smtp_port).to eq(587)
      expect(Setting.smtp_user_name).to eq('username')
      expect(Setting.smtp_enable_starttls_auto?).to eq(true)
      expect(Setting.smtp_ssl?).to eq(true)
    end
  end

  describe '.reload_mailer_configuration!' do
    let(:action_mailer) { double('ActionMailer::Base', smtp_settings: {}, deliveries: []) }

    before do
      stub_const('ActionMailer::Base', action_mailer)
    end

    after do
      # reload configuration to isolate specs
      described_class.load
      # clear settings cache to isolate specs
      Setting.clear_cache
    end

    it 'uses the legacy method to configure email settings' do
      described_class['email_delivery_configuration'] = 'legacy'
      expect(described_class).to receive(:configure_legacy_action_mailer)
      described_class.reload_mailer_configuration!
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
      Setting.smtp_ssl = 0

      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      described_class.reload_mailer_configuration!
      expect(action_mailer.smtp_settings[:smtp_authentication]).to be_nil
      expect(action_mailer.smtp_settings).to eq(address: 'smtp.example.com',
                                                port: 25,
                                                domain: 'example.com',
                                                enable_starttls_auto: true,
                                                ssl: false)

      Setting.email_delivery_method = :smtp
      Setting.smtp_authentication = :none
      Setting.smtp_password = 'old'
      Setting.smtp_address = 'smtp.example.com'
      Setting.smtp_domain = 'example.com'
      Setting.smtp_port = 25
      Setting.smtp_user_name = 'username'
      Setting.smtp_enable_starttls_auto = 0
      Setting.smtp_ssl = 1

      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      described_class.reload_mailer_configuration!
      expect(action_mailer.smtp_settings[:smtp_authentication]).to be_nil
      expect(action_mailer.smtp_settings).to eq(address: 'smtp.example.com',
                                                port: 25,
                                                domain: 'example.com',
                                                enable_starttls_auto: false,
                                                ssl: true)
    end

    it 'correctly sets the action mailer configuration based on the settings' do
      Setting.email_delivery_method = :smtp
      Setting.smtp_password = 'p4ssw0rd'
      Setting.smtp_address = 'smtp.example.com'
      Setting.smtp_domain = 'example.com'
      Setting.smtp_port = 587
      Setting.smtp_user_name = 'username'
      Setting.smtp_enable_starttls_auto = 1
      Setting.smtp_ssl = 0

      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      described_class.reload_mailer_configuration!
      expect(action_mailer.smtp_settings).to eq(address: 'smtp.example.com',
                                                port: 587,
                                                domain: 'example.com',
                                                authentication: 'plain',
                                                user_name: 'username',
                                                password: 'p4ssw0rd',
                                                enable_starttls_auto: true,
                                                ssl: false)

      Setting.email_delivery_method = :smtp
      Setting.smtp_password = 'p4ssw0rd'
      Setting.smtp_address = 'smtp.example.com'
      Setting.smtp_domain = 'example.com'
      Setting.smtp_port = 587
      Setting.smtp_user_name = 'username'
      Setting.smtp_enable_starttls_auto = 0
      Setting.smtp_ssl = 1

      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      described_class.reload_mailer_configuration!
      expect(action_mailer.smtp_settings).to eq(address: 'smtp.example.com',
                                                port: 587,
                                                domain: 'example.com',
                                                authentication: 'plain',
                                                user_name: 'username',
                                                password: 'p4ssw0rd',
                                                enable_starttls_auto: false,
                                                ssl: true)
    end
  end

  describe '.configure_legacy_action_mailer' do
    let(:action_mailer) do
      class_double('ActionMailer::Base',
                   deliveries: []).tap do |mailer|
        allow(mailer).to receive(:perform_deliveries=)
        allow(mailer).to receive(:delivery_method=)
        allow(mailer).to receive(:smtp_settings=)
      end
    end
    let(:config) do
      { 'email_delivery_method' => 'smtp',
        'smtp_address' => 'smtp.example.net',
        'smtp_port' => '25' }
    end

    before do
      stub_const('ActionMailer::Base', action_mailer)
    end

    it 'enables deliveries and configure ActionMailer smtp delivery' do
      described_class.send(:configure_legacy_action_mailer, config)

      expect(action_mailer)
        .to have_received(:perform_deliveries=)
              .with(true)
      expect(action_mailer)
        .to have_received(:delivery_method=)
              .with(:smtp)
      expect(action_mailer)
        .to have_received(:smtp_settings=)
              .with(address: 'smtp.example.net',
                    port: '25')
    end
  end

  describe '.configure_cache' do
    let(:application_config) do
      Rails::Application::Configuration.new Rails.root
    end

    after do
      # reload configuration to isolate specs
      described_class.load
    end

    context 'with cache store already set' do
      before do
        application_config.cache_store = 'foo'
      end

      context 'with additional cache store configuration' do
        before do
          described_class['rails_cache_store'] = 'bar'
        end

        it 'changes the cache store' do
          described_class.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq([:bar])
        end
      end

      context 'without additional cache store configuration' do
        before do
          described_class['rails_cache_store'] = nil
        end

        it 'does not change the cache store' do
          described_class.send(:configure_cache, application_config)
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
          described_class['rails_cache_store'] = 'bar'
        end

        it 'changes the cache store' do
          described_class.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq([:bar])
        end
      end

      context 'without additional cache store configuration' do
        before do
          described_class['rails_cache_store'] = nil
        end

        it 'defaults the cache store to :file_store' do
          described_class.send(:configure_cache, application_config)
          expect(application_config.cache_store.first).to eq(:file_store)
        end
      end
    end
  end

  describe 'helpers' do
    describe '#direct_uploads?' do
      let(:value) { described_class.direct_uploads? }

      it 'is false by default' do
        expect(value).to be false
      end

      context 'with remote storage' do
        def self.storage(provider)
          {
            attachments_storage: :fog,
            fog: {
              credentials: {
                provider: provider
              }
            }
          }
        end

        context 'AWS', with_config: storage('AWS') do
          it 'is true' do
            expect(value).to be true
          end
        end

        context 'Azure', with_config: storage('azure') do
          it 'is false' do
            expect(value).to be false
          end
        end
      end
    end
  end
end
