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

    delegate :tenant, to: :omniauth_provider, allow_nil: false
    delegate :use_graph_api, to: :omniauth_provider, allow_nil: false

    ##
    # Controls whether or not self registration shall be limited for this provider.
    #
    # See also:
    #   - OpenProject::Plugins::AuthPlugin.limit_self_registration?
    #   - OpenProject::AuthPlugins::Patches::RegisterUserServicePatch
    attr_reader :limit_self_registration

    def initialize(omniauth_provider)
      @omniauth_provider = omniauth_provider
      @errors = ActiveModel::Errors.new(self)
      @display_name = omniauth_provider.to_h[:display_name]
      @limit_self_registration = initial_value_for_limit_self_registration
    end

    def self.initialize_with(params)
      do_limit = params[:limit_self_registration]

      new(NewProvider.new(params.except(:limit_self_registration))).tap do |p|
        p.limit_self_registration = String(do_limit).to_bool unless do_limit.nil?
      end
    end

    def new_record?
      !persisted?
    end

    def persisted?
      omniauth_provider.is_a?(OmniAuth::OpenIDConnect::Provider)
    end

    def limit_self_registration?
      @limit_self_registration
    end

    def limit_self_registration=(value)
      @limit_self_registration = value
    end

    def to_h
      return {} if omniauth_provider.nil?

      omniauth_provider.to_h.merge(limit_self_registration: limit_self_registration?)
    end

    def limit_self_registration_default
      name == "google" # limit by default only for Google since anyone can sign in
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

    private

    def initial_value_for_limit_self_registration
      if omniauth_provider.configuration&.has_key? :limit_self_registration
        omniauth_provider.configuration[:limit_self_registration]
      else
        limit_self_registration_default
      end
    end
  end
end
