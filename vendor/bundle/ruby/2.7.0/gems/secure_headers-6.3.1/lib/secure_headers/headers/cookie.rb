# frozen_string_literal: true
require "cgi"
require "secure_headers/utils/cookies_config"


module SecureHeaders
  class CookiesConfigError < StandardError; end
  class Cookie

    class << self
      def validate_config!(config)
        CookiesConfig.new(config).validate!
      end
    end

    attr_reader :raw_cookie, :config

    COOKIE_DEFAULTS = {
      httponly: true,
      secure: true,
      samesite: { lax: true },
    }.freeze

    def initialize(cookie, config)
      @raw_cookie = cookie
      unless config == OPT_OUT
        config ||= {}
        config = COOKIE_DEFAULTS.merge(config)
      end
      @config = config
      @attributes = {
        httponly: nil,
        samesite: nil,
        secure: nil,
      }

      parse(cookie)
    end

    def to_s
      @raw_cookie.dup.tap do |c|
        c << "; secure" if secure?
        c << "; HttpOnly" if httponly?
        c << "; #{samesite_cookie}" if samesite?
      end
    end

    def secure?
      flag_cookie?(:secure) && !already_flagged?(:secure)
    end

    def httponly?
      flag_cookie?(:httponly) && !already_flagged?(:httponly)
    end

    def samesite?
      flag_samesite? && !already_flagged?(:samesite)
    end

    private

    def parsed_cookie
      @parsed_cookie ||= CGI::Cookie.parse(raw_cookie)
    end

    def already_flagged?(attribute)
      @attributes[attribute]
    end

    def flag_cookie?(attribute)
      return false if config == OPT_OUT
      case config[attribute]
      when TrueClass
        true
      when Hash
        conditionally_flag?(config[attribute])
      else
        false
      end
    end

    def conditionally_flag?(configuration)
      if(Array(configuration[:only]).any? && (Array(configuration[:only]) & parsed_cookie.keys).any?)
        true
      elsif(Array(configuration[:except]).any? && (Array(configuration[:except]) & parsed_cookie.keys).none?)
        true
      else
        false
      end
    end

    def samesite_cookie
      if flag_samesite_lax?
        "SameSite=Lax"
      elsif flag_samesite_strict?
        "SameSite=Strict"
      elsif flag_samesite_none?
        "SameSite=None"
      end
    end

    def flag_samesite?
      return false if config == OPT_OUT || config[:samesite] == OPT_OUT
      flag_samesite_lax? || flag_samesite_strict? || flag_samesite_none?
    end

    def flag_samesite_lax?
      flag_samesite_enforcement?(:lax)
    end

    def flag_samesite_strict?
      flag_samesite_enforcement?(:strict)
    end

    def flag_samesite_none?
      flag_samesite_enforcement?(:none)
    end

    def flag_samesite_enforcement?(mode)
      return unless config[:samesite]

      if config[:samesite].is_a?(TrueClass) && mode == :lax
        return true
      end

      case config[:samesite][mode]
      when Hash
        conditionally_flag?(config[:samesite][mode])
      when TrueClass
        true
      else
        false
      end
    end

    def parse(cookie)
      return unless cookie

      cookie.split(/[;,]\s?/).each do |pairs|
        name, values = pairs.split("=", 2)
        name = CGI.unescape(name)

        attribute = name.downcase.to_sym
        if @attributes.has_key?(attribute)
          @attributes[attribute] = values || true
        end
      end
    end
  end
end
