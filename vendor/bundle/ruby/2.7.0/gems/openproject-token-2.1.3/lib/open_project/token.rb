require "openssl"
require "date"
require "json"
require "base64"

require 'active_model'

require "open_project/token/version"
require "open_project/token/extractor"
require "open_project/token/armor"

module OpenProject
  class Token
    class Error < StandardError; end
    class ImportError < Error; end
    class ParseError < Error; end
    class ValidationError < Error; end

    class << self
      attr_reader :key, :extractor

      def key=(key)
        if key && !key.is_a?(OpenSSL::PKey::RSA)
          raise ArgumentError, "Key is missing."
        end

        @key = key
        @extractor = Extractor.new(self.key)
      end

      def import(data)
        raise ImportError, "Missing key." if key.nil?
        raise ImportError, "No token data." if data.nil?

        data = Armor.decode(data)
        json = extractor.read(data)
        attributes = JSON.parse(json)

        new(attributes)
      rescue Extractor::Error
        raise ImportError, "Token value could not be read."
      rescue JSON::ParserError
        raise ImportError, "Token value is invalid JSON."
      rescue Armor::ParseError
        raise ImportError, "Token value could not be parsed."
      end
    end

    include ActiveModel::Validations

    attr_reader :version
    attr_accessor :subscriber, :mail, :company, :domain
    attr_accessor :starts_at, :issued_at, :expires_at
    attr_accessor :notify_admins_at, :notify_users_at, :block_changes_at
    attr_accessor :restrictions

    validates_presence_of :subscriber
    validates_presence_of :mail
    validates_presence_of :company, allow_blank: true
    validates_presence_of :domain, if: :validate_domain?

    validates_each(
      :starts_at, :issued_at, :expires_at, :notify_admins_at, :notify_users_at, :block_changes_at,
      allow_blank: true) do |record, attr, value|

      record.errors.add attr, 'is not a date' if !value.is_a?(Date)
    end

    validates_each :restrictions, allow_nil: true do |record, attr, value|
      record.errors.add attr, :invalid if !value.is_a?(Hash)
    end

    def initialize(attributes = {})
      load_attributes(attributes)
    end

    def will_expire?
      self.expires_at
    end

    def will_notify_admins?
      self.notify_admins_at
    end

    def will_notify_users?
      self.notify_users_at
    end

    def will_block_changes?
      self.block_changes_at
    end

    def expired?
      will_expire? && Date.today >= self.expires_at
    end

    def notify_admins?
      will_notify_admins? && Date.today >= self.notify_admins_at
    end

    def notify_users?
      will_notify_users? && Date.today >= self.notify_users_at
    end

    def block_changes?
      will_block_changes? && Date.today >= self.block_changes_at
    end

    # tokens with no version or a version lower than 2.0 don't have the attributes company or domain
    def validate_domain?
      version && Gem::Version.new(version) >= domain_required_from_version
    end

    def restricted?(key = nil)
      if key
        restricted? && restrictions.has_key?(key)
      else
        restrictions && restrictions.length >= 1
      end
    end

    def attributes
      hash = {}

      hash["version"]          = self.version
      hash["subscriber"]       = self.subscriber
      hash["mail"]             = self.mail
      hash["company"]          = self.company
      hash["domain"]           = self.domain

      hash["issued_at"]        = self.issued_at
      hash["starts_at"]        = self.starts_at
      hash["expires_at"]       = self.expires_at       if self.will_expire?

      hash["notify_admins_at"] = self.notify_admins_at if self.will_notify_admins?
      hash["notify_users_at"]  = self.notify_users_at  if self.will_notify_users?
      hash["block_changes_at"] = self.block_changes_at if self.will_block_changes?

      hash["restrictions"]     = self.restrictions     if self.restricted?

      hash
    end

    def to_json
      JSON.dump(self.attributes)
    end

    def from_json(json)
      load_attributes(JSON.parse(json))
    rescue => e
      raise ParseError, "Failed to load from json: #{e}"
    end

    private

    def load_attributes(attributes)
      attributes = Hash[attributes.map { |k, v| [k.to_s, v] }]

      @version = read_version attributes
      @subscriber = attributes["subscriber"]
      @mail = attributes["mail"]
      @company = attributes["company"]
      @domain = attributes["domain"]

      date_attribute_keys.each do |attr|
        value = attributes[attr]
        value = Date.parse(value) rescue nil if value.is_a?(String)

        next unless value

        send("#{attr}=", value)
      end

      restrictions = attributes["restrictions"]

      if restrictions && restrictions.is_a?(Hash)
        restrictions = Hash[restrictions.map { |k, v| [k.to_sym, v] }]
        @restrictions = restrictions
      end
    end

    ##
    # Reads the version from the given attributes hash.
    # Besides the usual values it allows for a special value `-1`.
    # This is then results in the version being `nil` specifically rather than
    # the current gem version by default.
    #
    # This way the generated token will get what ever version the importing party
    # has. This is important due to a bug in openproject-token 1.x where any version
    # other than `nil` (or the integer literal 1) results in a "Version is too new" error.
    # This affects all OpenProject installations with a version older than 10.6
    # which will run into internal server errors trying to activate their Enterprise
    # tokens due to this.
    #
    # Generating tokens with version `-1` prevents that.
    #
    # @param attr [Hash] Parsed token attributes.
    def read_version(attr)
      value = attr.include?("version") ? attr["version"] : current_gem_version.to_s
      version = nil

      if value.present? && value.to_s != "-1"
        version = Gem::Version.new value

        if version > current_gem_version
          raise ArgumentError, "Version is too new"
        end
      end

      version
    end

    def date_attribute_keys
      %w(starts_at issued_at expires_at notify_admins_at notify_users_at block_changes_at)
    end

    def current_gem_version
      @current_gem_version ||= Gem::Version.new(OpenProject::Token::VERSION.to_s)
    end

    def domain_required_from_version
      @domain_required_from_version ||= Gem::Version.new('2.0')
    end
  end
end
