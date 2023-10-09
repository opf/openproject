module OpenIDConnect
  class Provider
    ALLOWED_TYPES = ["azure", "google"].freeze

    class NewProvider < OpenStruct
      def to_h
        @table.compact
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

    delegate :tenant, to: :omniauth_provider, allow_nil: false
    delegate :configuration, to: :omniauth_provider, allow_nil: true
    delegate :use_graph_api, to: :omniauth_provider, allow_nil: false

    def initialize(omniauth_provider)
      @omniauth_provider = omniauth_provider
      @errors = ActiveModel::Errors.new(self)
      @display_name = omniauth_provider.to_h[:display_name]
    end

    def self.initialize_with(params)
      normalized = normalized_params(params)

      # We want all providers to be limited by the self registration setting by default
      normalized.reverse_merge!(limit_self_registration: true)

      new(NewProvider.new(normalized))
    end

    def self.normalized_params(params)
      transformed = %i[limit_self_registration use_graph_api].filter_map do |key|
        if params.key?(key)
          value = params[key]
          [key, ActiveRecord::Type::Boolean.new.deserialize(value)]
        end
      end

      params.merge(transformed.to_h)
    end

    def new_record?
      !persisted?
    end

    def persisted?
      omniauth_provider.is_a?(OmniAuth::OpenIDConnect::Provider)
    end

    def limit_self_registration
      (configuration || {}).fetch(:limit_self_registration, true)
    end

    alias_method :limit_self_registration?, :limit_self_registration

    def to_h
      return {} if omniauth_provider.nil?

      omniauth_provider.to_h
    end

    def id
      return nil unless persisted?

      name
    end

    def valid?
      @errors.add(:name, :invalid) unless type_allowed?(name)
      @errors.add(:identifier, :blank) if identifier.blank?
      @errors.add(:secret, :blank) if secret.blank?
      @errors.none?
    end

    ##
    # Checks if the provider with the given name is of an allowed type.
    #
    # Types can be followed by a period and arbitrary names to add several
    # providers of the same type. E.g. 'azure', 'azure.dep1', 'azure.dep2'.
    def type_allowed?(name)
      ALLOWED_TYPES.any? { |allowed| name =~ /\A#{allowed}(\..+)?\Z/ }
    end

    def save
      return false unless valid?

      Setting.plugin_openproject_openid_connect = setting_with_provider

      true
    end

    def destroy
      Setting.plugin_openproject_openid_connect = setting_without_provider

      true
    end

    def setting_with_provider
      setting.deep_merge "providers" => { name => to_h.stringify_keys }
    end

    def setting_without_provider
      setting.tap do |s|
        s["providers"].delete name
      end
    end

    def setting
      Hash(Setting.plugin_openproject_openid_connect).tap do |h|
        h["providers"] ||= Hash.new
      end
    end

    # https://api.rubyonrails.org/classes/ActiveModel/Errors.html
    def read_attribute_for_validation(attr)
      send(attr)
    end
  end
end
