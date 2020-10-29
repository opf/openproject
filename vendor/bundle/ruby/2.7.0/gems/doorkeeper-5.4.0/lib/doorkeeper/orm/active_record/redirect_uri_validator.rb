# frozen_string_literal: true

require "uri"

module Doorkeeper
  # ActiveModel validator for redirect URI validation in according
  # to OAuth standards and Doorkeeper configuration.
  class RedirectUriValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      if value.blank?
        return if Doorkeeper.config.allow_blank_redirect_uri?(record)

        record.errors.add(attribute, :blank)
      else
        value.split.each do |val|
          next if oob_redirect_uri?(val)

          uri = ::URI.parse(val)
          record.errors.add(attribute, :forbidden_uri) if forbidden_uri?(uri)
          record.errors.add(attribute, :fragment_present) unless uri.fragment.nil?
          record.errors.add(attribute, :unspecified_scheme) if unspecified_scheme?(uri)
          record.errors.add(attribute, :relative_uri) if relative_uri?(uri)
          record.errors.add(attribute, :secured_uri) if invalid_ssl_uri?(uri)
        end
      end
    rescue URI::InvalidURIError
      record.errors.add(attribute, :invalid_uri)
    end

    private

    def oob_redirect_uri?(uri)
      Doorkeeper::OAuth::NonStandard::IETF_WG_OAUTH2_OOB_METHODS.include?(uri)
    end

    def forbidden_uri?(uri)
      Doorkeeper.config.forbid_redirect_uri.call(uri)
    end

    def unspecified_scheme?(uri)
      return true if uri.opaque.present?

      %w[localhost].include?(uri.try(:scheme))
    end

    def relative_uri?(uri)
      uri.scheme.nil? && uri.host.nil?
    end

    def invalid_ssl_uri?(uri)
      forces_ssl = Doorkeeper.config.force_ssl_in_redirect_uri
      non_https = uri.try(:scheme) == "http"

      if forces_ssl.respond_to?(:call)
        forces_ssl.call(uri) && non_https
      else
        forces_ssl && non_https
      end
    end
  end
end
