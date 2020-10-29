module OpenIDConnect
  class RequestObject
    module Claimable
      def self.included(klass)
        klass.send :attr_optional, :claims
      end

      def initialize(attributes = {})
        super
        if claims.present?
          _claims_ = {}
          claims.each do |key, value|
            _claims_[key] = case value
            when :optional, :voluntary
              {
                essential: false
              }
            when :required, :essential
              {
                essential: true
              }
            else
              value
            end
          end
          self.claims = _claims_.with_indifferent_access
        end
      end

      def as_json(options = {})
        keys = claims.try(:keys)
        hash = super
        Array(keys).each do |key|
          hash[:claims][key] ||= nil
        end
        hash
      end

      def required?(claim)
        accessible?(claim) && claims[claim].is_a?(Hash) && claims[claim][:essential]
      end
      alias_method :essential?, :required?

      def optional?(claim)
        accessible?(claim) && !required?(claim)
      end
      alias_method :voluntary?, :optional?

      def accessible?(claim)
        claims.try(:include?, claim)
      end
    end
  end
end