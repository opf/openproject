#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe Settings::Definition, :settings_reset do
  describe ".add_all" do
    it "adds all core setting definitions if they are not loaded" do
      described_class.instance_variable_set(:@all, nil)
      expect(described_class.all).to eq({})

      described_class.add_all

      expect(described_class.all.keys).to eq(described_class::DEFINITIONS.keys)
    end

    it "does not add any plugin/feature settings if they were removed for some reason" do
      not_core_settings = described_class.all.keys - described_class::DEFINITIONS.keys
      expect(not_core_settings).not_to be_empty
      described_class.instance_variable_set(:@all, nil)

      described_class.add_all

      expect(described_class.all.keys).not_to include(not_core_settings)
    end
  end

  describe ".all" do
    subject(:all) { described_class.all }

    it "is a hash map of setting definitions" do
      expect(all.class).to eq(Hash)
      expect(all.values).to(be_all { |d| d.is_a?(described_class) })
    end

    it "contains a definition from settings" do
      expect(all[:smtp_address]).to be_present
    end

    it "contains a definition from configuration" do
      expect(all[:edition]).to be_present
    end

    it "contains a definition from settings.yml" do
      expect(all[:sendmail_location]).to be_present
    end

    it "casts the value from settings.yml" do
      expect(all[:brute_force_block_after_failed_logins].value).to eq(20)
    end

    context "when overriding from ENV",
            with_env: {
              "OPENPROJECT_EDITION" => "bim",
              "OPENPROJECT_DEFAULT__LANGUAGE" => "de"
            } do
      it "allows overriding configuration from ENV with OPENPROJECT_ prefix with double underscore case (legacy)" do
        reset(:edition)
        reset(:default_language)

        expect(all[:edition].value).to eql "bim"
        expect(all[:default_language].value).to eql "de"
      end

      it "allows overriding configuration from ENV with OPENPROJECT_ prefix with single underscore case",
         with_env: { "OPENPROJECT_DEFAULT_LANGUAGE" => "de" } do
        reset(:default_language)
        expect(all[:default_language].value).to eql "de"
      end

      it "allows overriding configuration from ENV without OPENPROJECT_ prefix",
         with_env: { "EDITION" => "bim" } do
        reset(:edition)
        expect(all[:edition].value).to eql "bim"
      end

      it "does not allows overriding configuration from ENV without OPENPROJECT_ prefix if setting is writable",
         with_env: { "DEFAULT_LANGUAGE" => "de" } do
        reset(:default_language)
        expect(all[:default_language].value).to eql "en"
      end

      it "allows overriding email/smtp configuration from ENV without OPENPROJECT_ prefix even though setting is writable",
         with_env: {
           "EMAIL_DELIVERY_CONFIGURATION" => "legacy",
           "EMAIL_DELIVERY_METHOD" => "smtp",
           "SMTP_ADDRESS" => "smtp.somedomain.org",
           "SMTP_AUTHENTICATION" => "something",
           "SMTP_DOMAIN" => "email.bogus.abc",
           "SMTP_ENABLE_STARTTLS_AUTO" => "true",
           "SMTP_PASSWORD" => "password",
           "SMTP_PORT" => "987",
           "SMTP_USER_NAME" => "user",
           "SMTP_SSL" => "true"
         } do
        reset(:email_delivery_configuration)
        reset(:email_delivery_method)
        reset(:smtp_address)
        reset(:smtp_authentication)
        reset(:smtp_domain)
        reset(:smtp_enable_starttls_auto)
        reset(:smtp_password)
        reset(:smtp_port)
        reset(:smtp_user_name)
        reset(:smtp_ssl)

        expect(all[:email_delivery_configuration].value).to eql "legacy"
        expect(all[:email_delivery_method].value).to eq :smtp
        expect(all[:smtp_address].value).to eql "smtp.somedomain.org"
        expect(all[:smtp_authentication].value).to eql "something"
        expect(all[:smtp_domain].value).to eql "email.bogus.abc"
        expect(all[:smtp_enable_starttls_auto].value).to be true
        expect(all[:smtp_password].value).to eql "password"
        expect(all[:smtp_port].value).to eq 987
        expect(all[:smtp_user_name].value).to eq "user"
        expect(all[:smtp_ssl].value).to be true
      end

      it "logs a deprecation warning when overriding configuration from ENV without OPENPROJECT_ prefix",
         with_env: { "EDITION" => "bim" } do
        allow(Rails.logger).to receive(:warn)

        reset(:edition)

        expect(all[:edition].value).to eql "bim"
        expect(Rails.logger).to have_received(:warn)
                                  .with(a_string_including("use OPENPROJECT_EDITION instead of EDITION"))
      end

      it "overriding boolean configuration from ENV will cast the value",
         with_env: { "OPENPROJECT_REST__API__ENABLED" => "0" } do
        reset(:rest_api_enabled)
        expect(all[:rest_api_enabled].value).to be false
      end

      it "overriding symbol configuration having allowed values from ENV will cast the value before validation check",
         with_env: { "OPENPROJECT_RAILS__CACHE__STORE" => "memcache" } do
        reset(:rails_cache_store)
        expect(all[:rails_cache_store].value).to eq :memcache
      end

      it "overriding datetime configuration from ENV will cast the value",
         with_env: { "OPENPROJECT_CONSENT__TIME" => "2222-01-01" } do
        reset(:consent_time)
        expect(all[:consent_time].value).to eql DateTime.parse("2222-01-01")
      end

      it "overriding timezone configuration from ENV will cast the value",
         with_env: { "OPENPROJECT_USER__DEFAULT__TIMEZONE" => "Europe/Berlin" } do
        reset(:user_default_timezone)
        expect(all[:user_default_timezone].value).to eq "Europe/Berlin"
      end

      it "overriding timezone configuration from ENV with a bogus value",
         with_env: { "OPENPROJECT_USER__DEFAULT__TIMEZONE" => "foobar" } do
        expect { reset(:user_default_timezone) }.to raise_error(ArgumentError)
      end

      it "overriding configuration from ENV will set it to non writable",
         with_env: { "OPENPROJECT_EDITION" => "bim" } do
        reset(:edition)
        expect(all[:edition]).not_to be_writable
      end

      it "allows overriding settings array from ENV",
         with_env: { "OPENPROJECT_PASSWORD__ACTIVE__RULES" => YAML.dump(["lowercase"]) } do
        reset(:password_active_rules)
        expect(all[:password_active_rules].value).to eql ["lowercase"]
      end

      it "overriding settings from ENV will set it to non writable",
         with_env: { "OPENPROJECT_WELCOME__TITLE" => "Some title" } do
        reset(:welcome_title)
        expect(all[:welcome_title]).not_to be_writable
      end

      it "allows overriding settings hash partially from ENV",
         with_env: { "OPENPROJECT_REPOSITORY__CHECKOUT__DATA_GIT_ENABLED" => "1" } do
        reset(:repository_checkout_data)
        expect(all[:repository_checkout_data].value).to eql({
                                                              "git" => { "enabled" => 1 },
                                                              "subversion" => { "enabled" => 0 }
                                                            })
      end

      it "allows overriding settings hash partially from ENV with single underscore name",
         with_env: { "OPENPROJECT_REPOSITORY_CHECKOUT_DATA_GIT_ENABLED" => "1" } do
        reset(:repository_checkout_data)
        expect(all[:repository_checkout_data].value).to eql({
                                                              "git" => { "enabled" => 1 },
                                                              "subversion" => { "enabled" => 0 }
                                                            })
      end

      it "allows overriding settings hash partially from ENV with yaml data",
         with_env: { "OPENPROJECT_REPOSITORY_CHECKOUT_DATA" => "{git: {enabled: 1}}" } do
        reset(:repository_checkout_data)
        expect(all[:repository_checkout_data].value).to eql({
                                                              "git" => { "enabled" => 1 },
                                                              "subversion" => { "enabled" => 0 }
                                                            })
      end

      it "allows overriding settings hash fully from repeated ENV values" do
        stub_const(
          "ENV",
          {
            "OPENPROJECT_REPOSITORY__CHECKOUT__DATA" => "{hg: {enabled: 0}}",
            "OPENPROJECT_REPOSITORY__CHECKOUT__DATA_CVS_ENABLED" => "0",
            "OPENPROJECT_REPOSITORY_CHECKOUT_DATA_GIT_ENABLED" => "1",
            "OPENPROJECT_REPOSITORY_CHECKOUT_DATA_GIT_MINIMUM__VERSION" => "42",
            "OPENPROJECT_REPOSITORY_CHECKOUT_DATA_SUBVERSION_ENABLED" => "1"
          }
        )
        reset(:repository_checkout_data)
        expect(all[:repository_checkout_data].value).to eql({
                                                              "cvs" => { "enabled" => 0 },
                                                              "git" => { "enabled" => 1, "minimum_version" => 42 },
                                                              "hg" => { "enabled" => 0 },
                                                              "subversion" => { "enabled" => 1 }
                                                            })
      end

      it "allows overriding settings hash fully from ENV with yaml data" do
        stub_const(
          "ENV",
          {
            "OPENPROJECT_REPOSITORY_CHECKOUT_DATA" => '{git: {enabled: 1, key: "42"}, cvs: {enabled: 0}}'
          }
        )
        reset(:repository_checkout_data)
        expect(all[:repository_checkout_data].value).to eql({
                                                              "git" => { "enabled" => 1, "key" => "42" },
                                                              "cvs" => { "enabled" => 0 },
                                                              "subversion" => { "enabled" => 0 }
                                                            })
      end

      it "allows overriding settings hash fully from ENV with yaml data multiline" do
        stub_const(
          "ENV",
          {
            "OPENPROJECT_REPOSITORY_CHECKOUT_DATA" => <<~YML
              ---
              git:
                enabled: 1
                key: "42"
              cvs:
                enabled: 0
            YML
          }
        )
        reset(:repository_checkout_data)
        expect(all[:repository_checkout_data].value).to eql({
                                                              "git" => { "enabled" => 1, "key" => "42" },
                                                              "cvs" => { "enabled" => 0 },
                                                              "subversion" => { "enabled" => 0 }
                                                            })
      end

      it "allows overriding settings hash fully from ENV with json data" do
        stub_const(
          "ENV",
          {
            "OPENPROJECT_REPOSITORY_CHECKOUT_DATA" => '{"git": {"enabled": 1, "key": "42"}, "cvs": {"enabled": 0}}'
          }
        )
        reset(:repository_checkout_data)
        expect(all[:repository_checkout_data].value).to eql({
                                                              "git" => { "enabled" => 1, "key" => "42" },
                                                              "cvs" => { "enabled" => 0 },
                                                              "subversion" => { "enabled" => 0 }
                                                            })
      end

      it "allows overriding configuration array from ENV with yaml/json data" do
        stub_const(
          "ENV",
          {
            "OPENPROJECT_BLACKLISTED_ROUTES" => '["admin/info", "admin/plugins"]'
          }
        )
        reset(:blacklisted_routes)
        expect(all[:blacklisted_routes].value).to eq(["admin/info", "admin/plugins"])
      end

      it "allows overriding configuration array from ENV with space separated string" do
        stub_const(
          "ENV",
          {
            "OPENPROJECT_BLACKLISTED_ROUTES" => "admin/info admin/plugins"
          }
        )

        reset(:blacklisted_routes)
        expect(OpenProject::Configuration.blacklisted_routes)
          .to eq(["admin/info", "admin/plugins"])
        expect(Setting.blacklisted_routes)
          .to eq(["admin/info", "admin/plugins"])
      end

      it "allows overriding configuration array from ENV with single string" do
        stub_const(
          "ENV",
          {
            "OPENPROJECT_DISABLED__MODULES" => "repository"
          }
        )

        reset(:disabled_modules)
        expect(OpenProject::Configuration.disabled_modules)
          .to eq(["repository"])
        expect(Setting.disabled_modules)
          .to eq(["repository"])
      end

      context "with definitions from plugins" do
        it "allows overriding settings hash partially from ENV with aliased env name" do
          stub_const(
            "ENV",
            {
              "OPENPROJECT_2FA_ENFORCED" => "true",
              "OPENPROJECT_2FA_ALLOW__REMEMBER__FOR__DAYS" => "15"
            }
          )
          # override from env manually because these settings are added by plugin itself
          described_class.send(:override_value, all[:plugin_openproject_two_factor_authentication])
          expect(all[:plugin_openproject_two_factor_authentication].value).to eq(
            "active_strategies" => %i[totp webauthn],
            "enforced" => true,
            "allow_remember_for_days" => 15
          )
        end

        it "allows overriding settings hash from ENV with aliased env name" do
          stub_const(
            "ENV",
            {
              "OPENPROJECT_2FA" => '{"enforced": true, "allow_remember_for_days": 15}'
            }
          )
          # override from env manually because these settings are added by plugin itself
          described_class.send(:override_value, all[:plugin_openproject_two_factor_authentication])
          expect(all[:plugin_openproject_two_factor_authentication].value)
            .to eq({ "active_strategies" => %i[totp webauthn], "enforced" => true, "allow_remember_for_days" => 15 })
        end
      end

      it "does not handle ENV vars for which no definition exists",
         with_env: { "OPENPROJECT_BOGUS" => "1234" } do
        expect(all[:bogus]).to be_nil
      end

      it "handles ENV vars for definitions added after #all was called (e.g. in a module)",
         with_env: { "OPENPROJECT_BOGUS" => "1" } do
        described_class.add(:bogus, default: 0)
        expect(all[:bogus].value).to eq 1
      end
    end

    context "when overriding from file" do
      let(:configuration_yml) do
        <<~YAML
          ---
            default:
              edition: 'bim'
              sendmail_location: 'default_location'
              direct_uploads: false
              disabled_modules: 'repository'
              blacklisted_routes: 'admin/info admin/plugins'
            test:
              smtp_address: 'test address'
              sendmail_location: 'test location'
              bogus: 'bogusvalue'
              consent_time: '2222-01-01'
        YAML
      end

      before { stub_configuration_yml }

      it "overrides from file default" do
        reset(:edition)
        expect(all[:edition].value).to eql "bim"
      end

      it "marks the value overwritten from file default unwritable" do
        reset(:edition)
        expect(all[:edition]).not_to be_writable
      end

      it "overrides from file default path but once again from current env" do
        reset(:sendmail_location)
        expect(all[:sendmail_location].value).to eql "test location"
      end

      it "marks the value overwritten from file default and again from current unwritable" do
        reset(:sendmail_location)
        expect(all[:sendmail_location]).not_to be_writable
      end

      it "overrides from file current env" do
        reset(:smtp_address)
        expect(all[:smtp_address].value).to eql "test address"
      end

      it "marks the value overwritten from file current unwritable" do
        reset(:smtp_address)
        expect(all[:smtp_address]).not_to be_writable
      end

      it "does not accept undefined settings" do
        expect(all[:bogus]).to be_nil
      end

      it "correctly parses date objects" do
        reset(:consent_time)
        expect(all[:consent_time].value).to eql DateTime.parse("2222-01-01")
      end

      it "correctly converts a space separated string into array for array format" do
        reset(:disabled_modules)
        expect(all[:disabled_modules].value).to eq ["repository"]
        reset(:blacklisted_routes)
        expect(all[:blacklisted_routes].value).to eq ["admin/info", "admin/plugins"]
      end

      it "correctly overrides a default by a false value" do
        reset(:direct_uploads)
        expect(all[:direct_uploads].value).to be false
      end

      context "when Rails environment is test" do
        before do
          allow(Rails.env).to receive(:test?).and_return(true)
        end

        it "does not override from file default" do
          reset(:edition)
          expect(all[:edition].value).not_to eql "bim"
        end

        it "overrides from file current env" do
          reset(:smtp_address)
          expect(all[:smtp_address].value).to eql "test address"
        end
      end

      context "when having invalid values in the file" do
        let(:configuration_yml) do
          <<~YAML
            ---
              default:
                smtp_openssl_verify_mode: 'bogus'
          YAML
        end

        it "is invalid" do
          expect do
            reset(:smtp_openssl_verify_mode)
          end.to raise_error ArgumentError
        end
      end

      context "when overwritten from ENV",
              with_env: { "OPENPROJECT_SENDMAIL__LOCATION" => "env location" } do
        it "overrides from ENV" do
          reset(:sendmail_location)
          expect(all[:sendmail_location].value).to eql "env location"
        end

        it "marks the overwritten value unwritable" do
          reset(:sendmail_location)
          expect(all[:sendmail_location]).not_to be_writable
        end
      end
    end

    context "when adding an additional setting" do
      it "includes the setting" do
        described_class.add("bogus", default: 1, format: :integer)
        expect(all[:bogus].value).to eq(1)
      end
    end
  end

  describe ".[name]" do
    subject(:definition) { described_class[key] }

    context "with a string" do
      let(:key) { "smtp_address" }

      it "returns the definition matching the name" do
        expect(definition.name)
          .to eql key
      end
    end

    context "with a symbol" do
      let(:key) { :smtp_address }

      it "returns the definition matching the name" do
        expect(definition.name)
          .to eql key.to_s
      end
    end

    context "with a non existing key" do
      let(:key) { "bogus" }

      it "returns nil" do
        expect(definition)
          .to be_nil
      end
    end

    context "when adding a setting late", :settings_reset do
      let(:key) { "bogus" }

      before do
        described_class[key]

        described_class.add "bogus",
                            default: 1,
                            format: :integer
      end

      it "has the setting" do
        expect(definition.name)
          .to eql key.to_s
      end
    end
  end

  describe "#override_value" do
    let(:format) { :string }
    let(:default) { "abc" }

    let(:instance) do
      described_class
        .new "bogus",
             format:,
             default:
    end

    context "with string format" do
      before do
        instance.override_value("xyz")
      end

      it "overwrites the value" do
        expect(instance.value)
          .to eql "xyz"
      end

      it "does not overwrite the default" do
        expect(instance.default)
          .to eql "abc"
      end

      it "turns the definition unwritable" do
        expect(instance)
          .not_to be_writable
      end
    end

    context "with hash format" do
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
        instance.override_value({ abc: { "a" => 5 }, xyz: 2 })
      end

      it "deep merges and transforms keys to string" do
        expect(instance.value)
          .to eql({
                    "abc" => {
                      "a" => 5,
                      "b" => 2
                    },
                    "cde" => 1,
                    "xyz" => 2
                  })
      end

      it "does not overwrite the default" do
        expect(instance.default)
          .to eql({
                    "abc" => {
                      "a" => 1,
                      "b" => 2
                    },
                    "cde" => 1
                  })
      end

      it "turns the definition unwritable" do
        expect(instance)
          .not_to be_writable
      end
    end

    context "with array format" do
      let(:format) { :array }
      let(:default) { [1, 2, 3] }

      before do
        instance.override_value([4, 5, 6])
      end

      it "overwrites the value" do
        expect(instance.value)
          .to eql [4, 5, 6]
      end

      it "does not overwrite the default" do
        expect(instance.default)
          .to eql [1, 2, 3]
      end

      it "turns the definition unwritable" do
        expect(instance)
          .not_to be_writable
      end
    end

    context "with an invalid value" do
      let(:instance) do
        described_class
          .new "bogus",
               format:,
               default: "foo",
               allowed: %w[foo bar]
      end

      it "raises an error" do
        expect { instance.override_value("invalid") }
          .to raise_error ArgumentError
      end
    end
  end

  describe ".exists?" do
    context "with an existing setting" do
      it "is truthy" do
        expect(described_class)
          .to exist("smtp_address")
      end
    end

    context "with a non existing setting" do
      it "is truthy" do
        expect(described_class)
          .not_to exist("foobar")
      end
    end
  end

  describe ".new" do
    context "with all the attributes" do
      let(:instance) do
        described_class.new "bogus",
                            format: :integer,
                            default: 1,
                            writable: false,
                            allowed: [1, 2, 3]
      end

      it "has the name" do
        expect(instance.name)
          .to eql "bogus"
      end

      it "has the format (in symbol)" do
        expect(instance.format)
          .to eq :integer
      end

      it "has the default" do
        expect(instance.default)
          .to eq 1
      end

      it "has the value" do
        expect(instance.value)
          .to eq 1
      end

      it "is not serialized" do
        expect(instance)
          .not_to be_serialized
      end

      it "has the writable value" do
        expect(instance)
          .not_to be_writable
      end

      it "has the allowed value" do
        expect(instance.allowed)
          .to eql [1, 2, 3]
      end
    end

    context "with the minimal attributes (integer value)" do
      let(:instance) do
        described_class.new "bogus",
                            default: 1
      end

      it "has the name" do
        expect(instance.name)
          .to eql "bogus"
      end

      it "has the format (in symbol) deduced" do
        expect(instance.format)
          .to eq :integer
      end

      it "has the default" do
        expect(instance.default)
          .to eq 1
      end

      it "has the default frozen" do
        expect(instance.default)
          .to be_frozen
      end

      it "has the value" do
        expect(instance.value)
          .to eq 1
      end

      it "is not serialized" do
        expect(instance)
          .not_to be_serialized
      end

      it "has the writable value" do
        expect(instance)
          .to be_writable
      end
    end

    context "with the minimal attributes (hash value)" do
      let(:instance) do
        described_class.new "bogus",
                            default: { a: "b", c: { d: "e" } }
      end

      it "has the format (in symbol) deduced" do
        expect(instance.format)
          .to eq :hash
      end

      it "is serialized" do
        expect(instance)
          .to be_serialized
      end

      it "has the default frozen" do
        expect(instance.default)
          .to be_frozen
      end

      it "transforms keys to string" do
        expect(instance.value)
          .to eq({
                   "a" => "b",
                   "c" => { "d" => "e" }
                 })
      end
    end

    context "with the minimal attributes (array value)" do
      let(:instance) do
        described_class.new "bogus",
                            default: %i[a b]
      end

      it "has the format (in symbol) deduced" do
        expect(instance.format)
          .to eq :array
      end

      it "is serialized" do
        expect(instance)
          .to be_serialized
      end
    end

    context "with the minimal attributes (true value)" do
      let(:instance) do
        described_class.new "bogus",
                            default: true
      end

      it "has the format (in symbol) deduced" do
        expect(instance.format)
          .to eq :boolean
      end
    end

    context "with the minimal attributes (false value)" do
      let(:instance) do
        described_class.new "bogus",
                            default: false
      end

      it "has the format (in symbol) deduced" do
        expect(instance.format)
          .to eq :boolean
      end
    end

    context "with the minimal attributes (date value)" do
      let(:instance) do
        described_class.new "bogus",
                            default: Time.zone.today
      end

      it "has the format (in symbol) deduced" do
        expect(instance.format)
          .to eq :date
      end
    end

    context "with the minimal attributes (datetime value)" do
      let(:instance) do
        described_class.new "bogus",
                            default: DateTime.now
      end

      it "has the format (in symbol) deduced" do
        expect(instance.format)
          .to eq :date_time
      end
    end

    context "with the minimal attributes (string value)" do
      let(:instance) do
        described_class.new "bogus",
                            default: "abc"
      end

      it "has the format (in symbol) deduced" do
        expect(instance.format)
          .to eq :string
      end
    end

    context "with procs for value, writable and allowed" do
      let(:instance) do
        described_class.new "bogus",
                            format: "string",
                            default: -> { "some value" },
                            writable: -> { false },
                            allowed: -> { %w[a b c] }
      end

      it "returns the procs return value for default" do
        expect(instance.default)
          .to eql "some value"
      end

      it "returns the procs return value for value" do
        expect(instance.value)
          .to eql "some value"
      end

      it "returns the procs return value for writable" do
        expect(instance)
          .not_to be_writable
      end

      it "returns the procs return value for allowed" do
        expect(instance.allowed)
          .to eql %w[a b c]
      end
    end

    context "with an integer provided as a string" do
      let(:instance) do
        described_class.new "bogus",
                            format: :integer,
                            default: "5"
      end

      it "returns default as an int" do
        expect(instance.default)
          .to eq 5
      end

      it "returns value as an int" do
        expect(instance.value)
          .to eq 5
      end
    end

    context "with a float provided as a string" do
      let(:instance) do
        described_class.new "bogus",
                            format: :float,
                            default: "0.5"
      end

      it "returns default as a float" do
        expect(instance.default)
          .to eq 0.5
      end

      it "returns value as a float" do
        expect(instance.value)
          .to eq 0.5
      end
    end

    context "with a boolean provided with a proc default" do
      let(:instance) do
        described_class.new "bogus",
                            format: :boolean,
                            default: -> { false }
      end

      it "calls the proc as a default" do
        expect(instance.default)
          .to be false
      end
    end
  end
end
