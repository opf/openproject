module Saml
  class Provider < OpenStruct
    DEFAULT_NAME_IDENTIFIER_FORMAT = 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'.freeze

    include ActiveModel::Validations
    include ActiveModel::Conversion

    attr_accessor :readonly
    validates_presence_of :display_name

    def initialize(readonly: false, **attributes)
      self.readonly = readonly
      super(attributes)

      set_default_attributes(attributes)
    end

    def id
      name
    end

    def name
      super.presence || "saml-#{uuid}"
    end

    def sp_entity_id
      super.presence || issuer.presence || url_helpers.root_url
    end

    def attribute_statements
      super.presence || {}
    end

    %w[login email first_name last_name].each do |accessor|
      define_method("#{accessor}_mapping") do
        value = attribute_statements[accessor]
        warn value
        if value.is_a?(Array)
          value.join(', ')
        else
          value
        end
      end

      define_method("#{accessor}_mapping=") do |newval|
        parsed = newval.split(/\s*,\s*/)
        attribute_statements[accessor] = parsed
      end
    end

    def new_record?
      !persisted?
    end

    def persisted?
      uuid.present?
    end

    def limit_self_registration?
      limit_self_registration
    end

    def save
      return false unless valid?

      Setting.plugin_openproject_auth_saml = setting_with_provider

      true
    end

    def destroy
      Setting.plugin_openproject_auth_saml = setting_without_provider

      true
    end

    def setting_with_provider
      setting.deep_merge "providers" => { name => to_h.stringify_keys }
    end

    def to_h
      super
        .reverse_merge(uuid: SecureRandom.uuid)
        .merge(derived_attributes)
    end

    def setting_without_provider
      setting.tap do |s|
        s["providers"].delete_if { |_, config| config['id'] == id }
      end
    end

    def setting
      Hash(Setting.plugin_openproject_auth_saml).tap do |h|
        h["providers"] ||= Hash.new
      end
    end

    private

    def set_default_attributes(attributes)
      self.limit_self_registration = attributes.fetch(:limit_self_registration, false)
      self.name_identifier_format = attributes.fetch(:name_identifier_format, DEFAULT_NAME_IDENTIFIER_FORMAT)
      self.issuer = attributes.fetch(:issuer, url_helpers.root_url)
      self.request_attributes = attributes.fetch(:request_attributes, default_request_attributes)
      self.uuid ||= SecureRandom.hex(4)
    end

    def default_request_attributes
      [
        {
          "name" => "mail",
          "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
          "friendly_name" => "Email address",
          "is_required" => true
        },
        {
          "name" => "givenName",
          "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
          "friendly_name" => "Given name",
          "is_required" => true
        },
        {
          "name" => "sn",
          "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
          "friendly_name" => "Family name",
          "is_required" => true
        },
        {
          "name" => "uid",
          "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
          "friendly_name" => "Stable unique ID / login of the user",
          "is_required" => true
        }
      ]
    end

    def derived_attributes
      {
        assertion_consumer_service_url: URI.join(url_helpers.root_url, "/auth/#{name}/callback").to_s,
      }
    end

    def url_helpers
      @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
    end
  end
end
