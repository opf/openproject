module OpenIDConnect
  class Provider
    ALLOWED_TYPES = ["azure", "google"].freeze

    class NewProvider < OpenStruct
      def to_h
        @table.dup.delete_if { |_k, v| v.blank? }
      end
    end

    extend ActiveModel::Naming
    include ActiveModel::Conversion
    extend ActiveModel::Translation
    attr_reader :errors, :omniauth_provider

    attr_accessor :display_name
    delegate :name, to: :omniauth_provider, allow_nil: true
    delegate :identifier, to: :omniauth_provider, allow_nil: true
    delegate :secret, to: :omniauth_provider, allow_nil: true
    delegate :scope, to: :omniauth_provider, allow_nil: true
    delegate :to_h, to: :omniauth_provider, allow_nil: false

    def initialize(omniauth_provider)
      @omniauth_provider = omniauth_provider
      @errors = ActiveModel::Errors.new(self)
      @display_name = omniauth_provider.to_h[:display_name]
    end

    def self.initialize_with(params)
      new(NewProvider.new(params))
    end

    def new_record?
      !persisted?
    end

    def persisted?
      omniauth_provider.is_a?(OmniAuth::OpenIDConnect::Provider)
    end

    def id
      return nil unless persisted?
      name
    end

    def valid?
      @errors.add(:name, :invalid) unless ALLOWED_TYPES.include?(name)
      @errors.add(:identifier, :blank) if identifier.blank?
      @errors.add(:secret, :blank) if secret.blank?
      @errors.none?
    end

    def save
      return false unless valid?
      config = Setting.plugin_openproject_openid_connect || Hash.new
      config["providers"] ||= Hash.new
      config["providers"][name] = omniauth_provider.to_h.stringify_keys
      Setting.plugin_openproject_openid_connect = config
      true
    end

    def destroy
      config = Setting.plugin_openproject_openid_connect
      config["providers"] ||= {}
      config["providers"].delete(name)
      Setting.plugin_openproject_openid_connect = config
      true
    end

    # https://api.rubyonrails.org/classes/ActiveModel/Errors.html
    def read_attribute_for_validation(attr)
      send(attr)
    end
  end
end
