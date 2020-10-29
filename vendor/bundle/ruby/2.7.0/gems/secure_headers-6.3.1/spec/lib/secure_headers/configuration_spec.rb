# frozen_string_literal: true
require "spec_helper"

module SecureHeaders
  describe Configuration do
    before(:each) do
      reset_config
    end

    it "has a default config" do
      expect(Configuration.default).to_not be_nil
    end

    it "has an 'noop' override" do
      Configuration.default
      expect(Configuration.overrides(Configuration::NOOP_OVERRIDE)).to_not be_nil
    end

    it "dup results in a copy of the default config" do
      Configuration.default
      original_configuration = Configuration.send(:default_config)
      configuration = Configuration.dup
      expect(original_configuration).not_to be(configuration)
      Configuration::CONFIG_ATTRIBUTES.each do |attr|
        expect(original_configuration.send(attr)).to eq(configuration.send(attr))
      end
    end

    it "stores an override" do
      Configuration.override(:test_override) do |config|
        config.x_frame_options = "DENY"
      end

      expect(Configuration.overrides(:test_override)).to_not be_nil
    end

    describe "#override" do
      it "raises on configuring an existing override" do
        set_override = Proc.new {
          Configuration.override(:test_override) do |config|
            config.x_frame_options = "DENY"
          end
        }

        set_override.call

        expect { set_override.call }
          .to raise_error(Configuration::AlreadyConfiguredError, "Configuration already exists")
      end

      it "raises when a named append with the given name exists" do
        Configuration.named_append(:test_override) do |config|
          config.x_frame_options = "DENY"
        end

        expect do
          Configuration.override(:test_override) do |config|
            config.x_frame_options = "SAMEORIGIN"
          end
        end.to raise_error(Configuration::AlreadyConfiguredError, "Configuration already exists")
      end
    end

    describe "#named_append" do
      it "raises on configuring an existing append" do
        set_override = Proc.new {
          Configuration.named_append(:test_override) do |config|
            config.x_frame_options = "DENY"
          end
        }

        set_override.call

        expect { set_override.call }
          .to raise_error(Configuration::AlreadyConfiguredError, "Configuration already exists")
      end

      it "raises when an override with the given name exists" do
        Configuration.override(:test_override) do |config|
          config.x_frame_options = "DENY"
        end

        expect do
          Configuration.named_append(:test_override) do |config|
            config.x_frame_options = "SAMEORIGIN"
          end
        end.to raise_error(Configuration::AlreadyConfiguredError, "Configuration already exists")
      end
    end

    it "deprecates the secure_cookies configuration" do
      expect {
        Configuration.default do |config|
          config.secure_cookies = true
        end
      }.to raise_error(ArgumentError)
    end

    it "gives cookies a default config" do
      expect(Configuration.default.cookies).to eq({httponly: true, secure: true, samesite: {lax: true}})
    end

    it "allows OPT_OUT" do
      Configuration.default do |config|
        config.cookies = OPT_OUT
      end

      config = Configuration.dup
      expect(config.cookies).to eq(OPT_OUT)
    end

    it "allows me to be explicit too" do
      Configuration.default do |config|
        config.cookies = {httponly: true, secure: true, samesite: {lax: false}}
      end

      config = Configuration.dup
      expect(config.cookies).to eq({httponly: true, secure: true, samesite: {lax: false}})
    end
  end
end
