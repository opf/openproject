#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Settings::Definition do
  describe '.all' do
    subject(:all) { described_class.all }

    it "is a list of setting definitions" do
      expect(all)
        .to(be_all { |d| d.is_a?(described_class) })
    end

    it 'contains a definition from settings' do
      expect(all)
        .to(be_any { |d| d.name == 'smtp_address' })
    end

    it 'contains a definition from configuration' do
      expect(all)
        .to(be_any { |d| d.name == 'edition' })
    end

    it 'contains a definition from settings.yml' do
      expect(all)
        .to(be_any { |d| d.name == 'sendmail_location' })
    end

    it 'casts the value from settings.yml' do
      expect(all.detect { |d| d.name == 'brute_force_block_after_failed_logins' }.value)
        .to eq 20
    end

    context 'when overriding from ENV', :settings_reset do
      def value_for(name)
        all.detect { |d| d.name == name }.value
      end

      it 'allows overriding configuration from ENV with OPENPROJECT_ prefix with double underscore case (legacy)' do
        stub_const('ENV',
                   {
                     'OPENPROJECT_EDITION' => 'bim',
                     'OPENPROJECT_DEFAULT__LANGUAGE' => 'de'
                   })

        expect(value_for('edition')).to eql 'bim'
        expect(value_for('default_language')).to eql 'de'
      end

      it 'allows overriding configuration from ENV with OPENPROJECT_ prefix with single underscore case' do
        stub_const('ENV', { 'OPENPROJECT_DEFAULT_LANGUAGE' => 'de' })

        expect(value_for('default_language')).to eql 'de'
      end

      it 'allows overriding configuration from ENV without OPENPROJECT_ prefix' do
        stub_const('ENV',
                   {
                     'EDITION' => 'bim'
                   })

        expect(value_for('edition')).to eql 'bim'
      end

      it 'does not allows overriding configuration from ENV without OPENPROJECT_ prefix if setting is writable' do
        stub_const('ENV',
                   {
                     'DEFAULT_LANGUAGE' => 'de'
                   })

        expect(value_for('default_language')).to eql 'en'
      end

      it 'allows overriding email/smtp configuration from ENV without OPENPROJECT_ prefix even though setting is writable' do
        stub_const('ENV',
                   {
                     'EMAIL_DELIVERY_CONFIGURATION' => 'legacy',
                     'EMAIL_DELIVERY_METHOD' => 'smtp',
                     'SMTP_ADDRESS' => 'smtp.somedomain.org',
                     'SMTP_AUTHENTICATION' => 'something',
                     'SMTP_DOMAIN' => 'email.bogus.abc',
                     'SMTP_ENABLE_STARTTLS_AUTO' => 'true',
                     'SMTP_PASSWORD' => 'password',
                     'SMTP_PORT' => '987',
                     'SMTP_USER_NAME' => 'user',
                     'SMTP_SSL' => 'true'
                   })

        expect(value_for('email_delivery_configuration')).to eql 'legacy'
        expect(value_for('email_delivery_method')).to eq :smtp
        expect(value_for('smtp_address')).to eql 'smtp.somedomain.org'
        expect(value_for('smtp_authentication')).to eql 'something'
        expect(value_for('smtp_domain')).to eql 'email.bogus.abc'
        expect(value_for('smtp_enable_starttls_auto')).to be true
        expect(value_for('smtp_password')).to eql 'password'
        expect(value_for('smtp_port')).to eq 987
        expect(value_for('smtp_user_name')).to eq 'user'
        expect(value_for('smtp_ssl')).to be true
      end

      it 'logs a deprecation warning when overriding configuration from ENV without OPENPROJECT_ prefix' do
        allow(Rails.logger).to receive(:warn)
        stub_const('ENV', { 'EDITION' => 'bim' })

        expect(value_for('edition')).to eql 'bim'
        expect(Rails.logger)
          .to have_received(:warn)
              .with(a_string_including("use OPENPROJECT_EDITION instead of EDITION"))
      end

      it 'overriding boolean configuration from ENV will cast the value' do
        stub_const('ENV', { 'OPENPROJECT_REST__API__ENABLED' => '0' })

        expect(all.detect { |d| d.name == 'rest_api_enabled' }.value)
          .to be false
      end

      it 'overriding datetime configuration from ENV will cast the value' do
        stub_const('ENV', { 'OPENPROJECT_CONSENT__TIME' => '2222-01-01' })

        expect(all.detect { |d| d.name == 'consent_time' }.value)
          .to eql DateTime.parse('2222-01-01')
      end

      it 'overriding timezone configuration from ENV will cast the value' do
        stub_const('ENV', { 'OPENPROJECT_USER__DEFAULT__TIMEZONE' => 'Europe/Berlin' })

        expect(value_for('user_default_timezone')).to eq 'Europe/Berlin'
      end

      it 'overriding timezone configuration from ENV with a bogus value' do
        stub_const('ENV', { 'OPENPROJECT_USER__DEFAULT__TIMEZONE' => 'foobar' })

        expect { value_for('user_default_timezone') }.to raise_error(ArgumentError)
      end

      it 'overriding configuration from ENV will set it to non writable' do
        stub_const('ENV', { 'OPENPROJECT_EDITION' => 'bim' })

        expect(all.detect { |d| d.name == 'edition' })
          .not_to be_writable
      end

      it 'allows overriding settings array from ENV' do
        stub_const('ENV', { 'OPENPROJECT_PASSWORD__ACTIVE__RULES' => YAML.dump(['lowercase']) })

        expect(all.detect { |d| d.name == 'password_active_rules' }.value)
          .to eql ['lowercase']
      end

      it 'overriding settings from ENV will set it to non writable' do
        stub_const('ENV', { 'OPENPROJECT_WELCOME__TITLE' => 'Some title' })

        expect(all.detect { |d| d.name == 'welcome_title' })
          .not_to be_writable
      end

      it 'allows overriding settings hash partially from ENV' do
        stub_const('ENV', { 'OPENPROJECT_REPOSITORY__CHECKOUT__DATA_GIT_ENABLED' => '1' })

        expect(value_for('repository_checkout_data'))
          .to eql({
                    'git' => { 'enabled' => 1 },
                    'subversion' => { 'enabled' => 0 }
                  })
      end

      it 'allows overriding settings hash partially from ENV with single underscore name' do
        stub_const('ENV', { 'OPENPROJECT_REPOSITORY_CHECKOUT_DATA_GIT_ENABLED' => '1' })

        expect(value_for('repository_checkout_data'))
          .to eql({
                    'git' => { 'enabled' => 1 },
                    'subversion' => { 'enabled' => 0 }
                  })
      end

      it 'allows overriding settings hash partially from ENV with yaml data' do
        stub_const('ENV', { 'OPENPROJECT_REPOSITORY_CHECKOUT_DATA' => '{git: {enabled: 1}}' })

        expect(value_for('repository_checkout_data'))
          .to eql({
                    'git' => { 'enabled' => 1 },
                    'subversion' => { 'enabled' => 0 }
                  })
      end

      it 'allows overriding settings hash fully from repeated ENV values' do
        stub_const(
          'ENV',
          {
            'OPENPROJECT_REPOSITORY__CHECKOUT__DATA' => '{hg: {enabled: 0}}',
            'OPENPROJECT_REPOSITORY__CHECKOUT__DATA_CVS_ENABLED' => '0',
            'OPENPROJECT_REPOSITORY_CHECKOUT_DATA_GIT_ENABLED' => '1',
            'OPENPROJECT_REPOSITORY_CHECKOUT_DATA_GIT_MINIMUM__VERSION' => '42',
            'OPENPROJECT_REPOSITORY_CHECKOUT_DATA_SUBVERSION_ENABLED' => '1'
          }
        )

        expect(value_for('repository_checkout_data'))
          .to eql({
                    'cvs' => { 'enabled' => 0 },
                    'git' => { 'enabled' => 1, 'minimum_version' => 42 },
                    'hg' => { 'enabled' => 0 },
                    'subversion' => { 'enabled' => 1 }
                  })
      end

      it 'allows overriding settings hash fully from ENV with yaml data' do
        stub_const(
          'ENV',
          {
            'OPENPROJECT_REPOSITORY_CHECKOUT_DATA' => '{git: {enabled: 1, key: "42"}, cvs: {enabled: 0}}'
          }
        )

        expect(all.detect { |d| d.name == 'repository_checkout_data' }.value)
          .to eql({
                    'git' => { 'enabled' => 1, 'key' => '42' },
                    'cvs' => { 'enabled' => 0 },
                    'subversion' => { 'enabled' => 0 }
                  })
      end

      it 'allows overriding settings hash fully from ENV with yaml data multiline' do
        stub_const(
          'ENV',
          {
            'OPENPROJECT_REPOSITORY_CHECKOUT_DATA' => <<~YML
              ---
              git:
                enabled: 1
                key: "42"
              cvs:
                enabled: 0
            YML
          }
        )

        expect(all.detect { |d| d.name == 'repository_checkout_data' }.value)
          .to eql({
                    'git' => { 'enabled' => 1, 'key' => '42' },
                    'cvs' => { 'enabled' => 0 },
                    'subversion' => { 'enabled' => 0 }
                  })
      end

      it 'allows overriding settings hash fully from ENV with json data' do
        stub_const(
          'ENV',
          {
            'OPENPROJECT_REPOSITORY_CHECKOUT_DATA' => '{"git": {"enabled": 1, "key": "42"}, "cvs": {"enabled": 0}}'
          }
        )

        expect(all.detect { |d| d.name == 'repository_checkout_data' }.value)
          .to eql({
                    'git' => { 'enabled' => 1, 'key' => '42' },
                    'cvs' => { 'enabled' => 0 },
                    'subversion' => { 'enabled' => 0 }
                  })
      end

      it 'allows overriding configuration array from ENV with yaml/json data' do
        stub_const(
          'ENV',
          {
            'OPENPROJECT_BLACKLISTED_ROUTES' => '["admin/info", "admin/plugins"]'
          }
        )

        expect(value_for('blacklisted_routes'))
          .to eq(['admin/info', 'admin/plugins'])
      end

      it 'allows overriding configuration array from ENV with space separated string' do
        stub_const(
          'ENV',
          {
            'OPENPROJECT_BLACKLISTED_ROUTES' => 'admin/info admin/plugins'
          }
        )

        # works for OpenProject::Configuration thanks to OpenProject::Configuration::Helper mixin
        expect(OpenProject::Configuration.blacklisted_routes)
          .to eq(['admin/info', 'admin/plugins'])
        # sadly behaves differently for Setting
        expect(Setting.blacklisted_routes)
          .to eq('admin/info admin/plugins')
      end

      context 'with definitions from plugins' do
        let(:definition_2fa) { definitions_before.find { _1.name == 'plugin_openproject_two_factor_authentication' }.dup }

        before do
          # hack to have access to Setting.plugin_openproject_two_factor_authentication after
          # having done
          described_class.all << definition_2fa
        end

        it 'allows overriding settings hash partially from ENV with aliased env name' do
          stub_const(
            'ENV',
            {
              'OPENPROJECT_2FA_ENFORCED' => 'true',
              'OPENPROJECT_2FA_ALLOW__REMEMBER__FOR__DAYS' => '15'
            }
          )

          described_class.send(:override_value, definition_2fa) # override from env manually after changing ENV
          expect(value_for('plugin_openproject_two_factor_authentication'))
            .to eq('active_strategies' => [:totp], 'enforced' => true, 'allow_remember_for_days' => 15)
        end

        it 'allows overriding settings hash from ENV with aliased env name' do
          stub_const(
            'ENV',
            {
              'OPENPROJECT_2FA' => '{"enforced": true, "allow_remember_for_days": 15}'
            }
          )
          described_class.send(:override_value, definition_2fa) # override from env manually after changing ENV
          expect(value_for('plugin_openproject_two_factor_authentication'))
            .to eq({ 'active_strategies' => [:totp], 'enforced' => true, 'allow_remember_for_days' => 15 })
        end
      end

      it 'will not handle ENV vars for which no definition exists' do
        stub_const('ENV', { 'OPENPROJECT_BOGUS' => '1' })

        expect(all.detect { |d| d.name == 'bogus' })
          .to be_nil
      end

      it 'will handle ENV vars for definitions added after #all was called (e.g. in a module)' do
        stub_const('ENV', { 'OPENPROJECT_BOGUS' => '1' })

        all

        described_class.add 'bogus',
                            default: 0

        expect(all.detect { |d| d.name == 'bogus' }.value)
          .to eq 1
      end
    end

    context 'when overriding from file', :settings_reset do
      let(:file_contents) do
        <<~YAML
          ---
            default:
              edition: 'bim'
              sendmail_location: 'default_location'
              direct_uploads: false
            test:
              smtp_address: 'test address'
              sendmail_location: 'test location'
              bogus: 'bogusvalue'
              consent_time: '2222-01-01'
        YAML
      end

      before do
        allow(File)
          .to receive(:file?)
                .with(Rails.root.join('config/configuration.yml'))
                .and_return(true)

        allow(File)
          .to receive(:read)
                .with(Rails.root.join('config/configuration.yml'))
                .and_return(file_contents)

        # Loading of the config file is partially disabled in test env
        allow(Rails.env)
          .to receive(:test?)
          .and_return(false)
      end

      it 'overrides from file default' do
        expect(all.detect { |d| d.name == 'edition' }.value)
          .to eql 'bim'
      end

      it 'marks the value overwritten from file default unwritable' do
        expect(all.detect { |d| d.name == 'edition' })
          .not_to be_writable
      end

      it 'overrides from file default path but once again from current env' do
        expect(all.detect { |d| d.name == 'sendmail_location' }.value)
          .to eql 'test location'
      end

      it 'marks the value overwritten from file default and again from current unwritable' do
        expect(all.detect { |d| d.name == 'sendmail_location' })
          .not_to be_writable
      end

      it 'overrides from file current env' do
        expect(all.detect { |d| d.name == 'smtp_address' }.value)
          .to eql 'test address'
      end

      it 'marks the value overwritten from file current unwritable' do
        expect(all.detect { |d| d.name == 'smtp_address' })
          .not_to be_writable
      end

      it 'does not accept undefined settings' do
        expect(all.detect { |d| d.name == 'bogus' })
          .to be_nil
      end

      it 'correctly parses date objects' do
        expect(all.detect { |d| d.name == 'consent_time' }.value)
          .to eql DateTime.parse("2222-01-01")
      end

      it 'correctly overrides a default by a false value' do
        expect(all.detect { |d| d.name == 'direct_uploads' }.value)
          .to be false
      end

      context 'when Rails environment is test' do
        before do
          allow(Rails.env)
            .to receive(:test?)
            .and_return(true)
        end

        it 'does not override from file default' do
          expect(all.detect { |d| d.name == 'edition' }.value)
            .not_to eql 'bim'
        end

        it 'overrides from file current env' do
          expect(all.detect { |d| d.name == 'smtp_address' }.value)
            .to eql 'test address'
        end
      end

      context 'when having invalid values in the file' do
        let(:file_contents) do
          <<~YAML
            ---
              default:
                smtp_openssl_verify_mode: 'bogus'
          YAML
        end

        it 'is invalid' do
          expect { all }
            .to raise_error ArgumentError
        end
      end

      context 'when overwritten from ENV' do
        before do
          stub_const('ENV', { 'OPENPROJECT_SENDMAIL__LOCATION' => 'env location' })
        end

        it 'overrides from ENV' do
          expect(all.detect { |d| d.name == 'sendmail_location' }.value)
            .to eql 'env location'
        end

        it 'marks the overwritten value unwritable' do
          expect(all.detect { |d| d.name == 'sendmail_location' })
            .not_to be_writable
        end
      end
    end

    context 'when adding an additional setting', :settings_reset do
      it 'includes the setting' do
        all

        described_class.add 'bogus',
                            default: 1,
                            format: :integer

        expect(all.detect { |d| d.name == 'bogus' }.value)
          .to eq(1)
      end
    end
  end

  describe ".[name]" do
    subject(:definition) { described_class[key] }

    context 'with a string' do
      let(:key) { 'smtp_address' }

      it 'returns the definition matching the name' do
        expect(definition.name)
          .to eql key
      end
    end

    context 'with a symbol' do
      let(:key) { :smtp_address }

      it 'returns the definition matching the name' do
        expect(definition.name)
          .to eql key.to_s
      end
    end

    context 'with a non existing key' do
      let(:key) { 'bogus' }

      it 'returns nil' do
        expect(definition)
          .to be_nil
      end
    end

    context 'when adding a setting late', :settings_reset do
      let(:key) { 'bogus' }

      before do
        described_class[key]

        described_class.add 'bogus',
                            default: 1,
                            format: :integer
      end

      it 'has the setting' do
        expect(definition.name)
          .to eql key.to_s
      end
    end
  end

  describe '#override_value' do
    let(:format) { :string }
    let(:default) { 'abc' }

    let(:instance) do
      described_class
        .new 'bogus',
             format:,
             default:
    end

    context 'with string format' do
      before do
        instance.override_value('xyz')
      end

      it 'overwrites the value' do
        expect(instance.value)
          .to eql 'xyz'
      end

      it 'does not overwrite the default' do
        expect(instance.default)
          .to eql 'abc'
      end

      it 'turns the definition unwritable' do
        expect(instance)
          .not_to be_writable
      end
    end

    context 'with hash format' do
      let(:format) { :hash }
      let(:default) do
        {
          abc: {
            a: 1,
            b: 2
          },
          cde: 1
        }
      end

      before do
        instance.override_value({ abc: { 'a' => 5 }, xyz: 2 })
      end

      it 'deep merges and transforms keys to string' do
        expect(instance.value)
          .to eql({
                    'abc' => {
                      'a' => 5,
                      'b' => 2
                    },
                    'cde' => 1,
                    'xyz' => 2
                  })
      end

      it 'does not overwrite the default' do
        expect(instance.default)
          .to eql({
                    'abc' => {
                      'a' => 1,
                      'b' => 2
                    },
                    'cde' => 1
                  })
      end

      it 'turns the definition unwritable' do
        expect(instance)
          .not_to be_writable
      end
    end

    context 'with array format' do
      let(:format) { :array }
      let(:default) { [1, 2, 3] }

      before do
        instance.override_value([4, 5, 6])
      end

      it 'overwrites the value' do
        expect(instance.value)
          .to eql [4, 5, 6]
      end

      it 'does not overwrite the default' do
        expect(instance.default)
          .to eql [1, 2, 3]
      end

      it 'turns the definition unwritable' do
        expect(instance)
          .not_to be_writable
      end
    end

    context 'with an invalid value' do
      let(:instance) do
        described_class
          .new 'bogus',
               format:,
               default: 'foo',
               allowed: %w[foo bar]
      end

      it 'raises an error' do
        expect { instance.override_value('invalid') }
          .to raise_error ArgumentError
      end
    end
  end

  describe '.exists?' do
    context 'with an existing setting' do
      it 'is truthy' do
        expect(described_class)
          .to exist('smtp_address')
      end
    end

    context 'with a non existing setting' do
      it 'is truthy' do
        expect(described_class)
          .not_to exist('foobar')
      end
    end
  end

  describe '.new' do
    context 'with all the attributes' do
      let(:instance) do
        described_class.new 'bogus',
                            format: :integer,
                            default: 1,
                            writable: false,
                            allowed: [1, 2, 3]
      end

      it 'has the name' do
        expect(instance.name)
          .to eql 'bogus'
      end

      it 'has the format (in symbol)' do
        expect(instance.format)
          .to eq :integer
      end

      it 'has the default' do
        expect(instance.default)
          .to eq 1
      end

      it 'has the value' do
        expect(instance.value)
          .to eq 1
      end

      it 'is not serialized' do
        expect(instance)
          .not_to be_serialized
      end

      it 'has the writable value' do
        expect(instance)
          .not_to be_writable
      end

      it 'has the allowed value' do
        expect(instance.allowed)
          .to eql [1, 2, 3]
      end
    end

    context 'with the minimal attributes (integer value)' do
      let(:instance) do
        described_class.new 'bogus',
                            default: 1
      end

      it 'has the name' do
        expect(instance.name)
          .to eql 'bogus'
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eq :integer
      end

      it 'has the default' do
        expect(instance.default)
          .to eq 1
      end

      it 'has the default frozen' do
        expect(instance.default)
          .to be_frozen
      end

      it 'has the value' do
        expect(instance.value)
          .to eq 1
      end

      it 'is not serialized' do
        expect(instance)
          .not_to be_serialized
      end

      it 'has the writable value' do
        expect(instance)
          .to be_writable
      end
    end

    context 'with the minimal attributes (hash value)' do
      let(:instance) do
        described_class.new 'bogus',
                            default: { a: 'b', c: { d: 'e' } }
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eq :hash
      end

      it 'is serialized' do
        expect(instance)
          .to be_serialized
      end

      it 'has the default frozen' do
        expect(instance.default)
          .to be_frozen
      end

      it 'transforms keys to string' do
        expect(instance.value)
          .to eq({
                   'a' => 'b',
                   'c' => { 'd' => 'e' }
                 })
      end
    end

    context 'with the minimal attributes (array value)' do
      let(:instance) do
        described_class.new 'bogus',
                            default: %i[a b]
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eq :array
      end

      it 'is serialized' do
        expect(instance)
          .to be_serialized
      end
    end

    context 'with the minimal attributes (true value)' do
      let(:instance) do
        described_class.new 'bogus',
                            default: true
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eq :boolean
      end
    end

    context 'with the minimal attributes (false value)' do
      let(:instance) do
        described_class.new 'bogus',
                            default: false
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eq :boolean
      end
    end

    context 'with the minimal attributes (date value)' do
      let(:instance) do
        described_class.new 'bogus',
                            default: Time.zone.today
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eq :date
      end
    end

    context 'with the minimal attributes (datetime value)' do
      let(:instance) do
        described_class.new 'bogus',
                            default: DateTime.now
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eq :date_time
      end
    end

    context 'with the minimal attributes (string value)' do
      let(:instance) do
        described_class.new 'bogus',
                            default: 'abc'
      end

      it 'has the format (in symbol) deduced' do
        expect(instance.format)
          .to eq :string
      end
    end

    context 'with procs for value, writable and allowed' do
      let(:instance) do
        described_class.new 'bogus',
                            format: 'string',
                            default: -> { 'some value' },
                            writable: -> { false },
                            allowed: -> { %w[a b c] }
      end

      it 'returns the procs return value for default' do
        expect(instance.default)
          .to eql 'some value'
      end

      it 'returns the procs return value for value' do
        expect(instance.value)
          .to eql 'some value'
      end

      it 'returns the procs return value for writable' do
        expect(instance)
          .not_to be_writable
      end

      it 'returns the procs return value for allowed' do
        expect(instance.allowed)
          .to eql %w[a b c]
      end
    end

    context 'with an integer provided as a string' do
      let(:instance) do
        described_class.new 'bogus',
                            format: :integer,
                            default: '5'
      end

      it 'returns default as an int' do
        expect(instance.default)
          .to eq 5
      end

      it 'returns value as an int' do
        expect(instance.value)
          .to eq 5
      end
    end

    context 'with a float provided as a string' do
      let(:instance) do
        described_class.new 'bogus',
                            format: :float,
                            default: '0.5'
      end

      it 'returns default as a float' do
        expect(instance.default)
          .to eq 0.5
      end

      it 'returns value as a float' do
        expect(instance.value)
          .to eq 0.5
      end
    end

    context 'with a boolean provided with a proc default' do
      let(:instance) do
        described_class.new 'bogus',
                            format: :boolean,
                            default: -> { false }
      end

      it 'calls the proc as a default' do
        expect(instance.default)
          .to be false
      end
    end
  end
end
