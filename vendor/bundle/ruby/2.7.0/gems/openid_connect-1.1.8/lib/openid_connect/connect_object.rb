module OpenIDConnect
  class ConnectObject
    include ActiveModel::Validations, AttrRequired, AttrOptional

    attr_accessor :raw_attributes

    def initialize(attributes = {})
      all_attributes.each do |_attr_|
        self.send :"#{_attr_}=", attributes[_attr_]
      end
      self.raw_attributes = attributes
      attr_missing!
    end

    def self.all_attributes
      required_attributes + optional_attributes
    end
    def all_attributes
      self.class.all_attributes
    end

    def require_at_least_one_attributes
      all_blank = all_attributes.all? do |key|
        self.send(key).blank?
      end
      errors.add :base, 'At least one attribute is required' if all_blank
    end

    def as_json(options = {})
      options ||= {} # options can be nil when to_json is called without options
      validate! unless options[:skip_validation]
      all_attributes.inject({}) do |hash, _attr_|
        value = self.send(_attr_)
        hash.merge! _attr_ => case value
        when ConnectObject
          value.as_json options
        else
          value
        end
      end.delete_if do |key, value|
        value.nil?
      end
    end

    def validate!
      valid? or raise ValidationFailed.new(self)
    end
  end
end

require 'openid_connect/request_object'
require 'openid_connect/response_object'