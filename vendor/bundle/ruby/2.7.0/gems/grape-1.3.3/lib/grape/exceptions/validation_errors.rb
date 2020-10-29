# frozen_string_literal: true

require 'grape/exceptions/base'

module Grape
  module Exceptions
    class ValidationErrors < Grape::Exceptions::Base
      ERRORS_FORMAT_KEY = 'grape.errors.format'
      DEFAULT_ERRORS_FORMAT = '%{attributes} %{message}'

      include Enumerable

      attr_reader :errors

      def initialize(errors: [], headers: {}, **_options)
        @errors = {}
        errors.each do |validation_error|
          @errors[validation_error.params] ||= []
          @errors[validation_error.params] << validation_error
        end

        super message: full_messages.join(', '), status: 400, headers: headers
      end

      def each
        errors.each_pair do |attribute, errors|
          errors.each do |error|
            yield attribute, error
          end
        end
      end

      def as_json(**_opts)
        errors.map do |k, v|
          {
            params: k,
            messages: v.map(&:to_s)
          }
        end
      end

      def to_json(**_opts)
        as_json.to_json
      end

      def full_messages
        messages = map do |attributes, error|
          I18n.t(
            ERRORS_FORMAT_KEY,
            default: DEFAULT_ERRORS_FORMAT,
            attributes: translate_attributes(attributes),
            message: error.message
          )
        end
        messages.uniq!
        messages
      end
    end
  end
end
