# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
module OpenIDConnect
  module Providers
    class BaseContract < ModelContract
      include RequiresAdminGuard

      VALID_CLAIMS_KEYS = %w[id_token userinfo].freeze

      def self.model
        OpenIDConnect::Provider
      end

      attribute :display_name
      attribute :oidc_provider
      validates :oidc_provider,
                presence: true,
                inclusion: { in: OpenIDConnect::Provider::OIDC_PROVIDERS }
      attribute :slug
      attribute :options
      attribute :limit_self_registration

      attribute :claims
      validate :claims_are_json

      attribute :acr_values

      %i[metadata_url authorization_endpoint userinfo_endpoint token_endpoint end_session_endpoint jwks_uri].each do |attr|
        attribute attr
        validates attr,
                  url: { allow_blank: true, allow_nil: true, schemes: %w[http https] },
                  if: -> { model.public_send(:"#{attr}_changed?") && !path_attribute?(model.public_send(attr)) }
      end

      attribute :post_logout_redirect_uri
      validates :post_logout_redirect_uri,
                url: { allow_blank: true, allow_nil: true, schemes: %w[http https] },
                if: -> { model.post_logout_redirect_uri_changed? }

      OpenIDConnect::Provider::MAPPABLE_ATTRIBUTES.each do |attr|
        attribute :"mapping_#{attr}"
      end

      attribute :groups_claim
      validates :groups_claim, presence: true, if: -> { model.sync_groups? }

      attribute :group_regexes
      validate :group_regexes_parseable

      private

      def path_attribute?(attr)
        attr.blank? || attr.start_with?("/")
      end

      def claims_are_json
        return if claims.blank?

        parsed = JSON.parse(claims)
        return errors.add(:claims, :not_json_object) unless parsed.is_a?(Hash)

        validate_claims_json_structure(parsed)
      rescue JSON::ParserError
        errors.add(:claims, :not_json)
      end

      def validate_claims_json_structure(parsed)
        invalid_keys = parsed.keys - VALID_CLAIMS_KEYS
        if invalid_keys.any?
          return errors.add(:claims,
                            :invalid_claims_location,
                            invalid: invalid_keys.join(", "),
                            supported: VALID_CLAIMS_KEYS.join(", "))
        end

        non_object_key, = parsed.find { |_, v| !v.is_a?(Hash) }
        return errors.add(:claims, :non_object_attribute, attribute: non_object_key) if non_object_key

        parsed.each_key do |key|
          validate_nested_claims_structure(parsed, key)
        end
      end

      def validate_nested_claims_structure(parsed, base_key)
        claims = parsed.fetch(base_key)
        claims.each do |key, value|
          next if value.nil?
          return errors.add(:claims, :non_object_attribute, attribute: json_path(base_key, key)) unless value.is_a?(Hash)
          if key_violates_type?(value, "essential", TrueClass, FalseClass)
            return errors.add(:claims, :invalid_claims_essential, attribute: json_path(base_key, key, "essential"))
          end
          if key_violates_type?(value, "values", Array)
            return errors.add(:claims, :invalid_claims_values, attribute: json_path(base_key, key, "values"))
          end
        end
      end

      def group_regexes_parseable
        invalid_lines = group_regexes.each_with_index.filter_map do |r, i|
          Regexp.new(r)
          nil
        rescue RegexpError
          i + 1
        end

        errors.add(:group_regexes, :regex_list_invalid, invalid_lines: invalid_lines.to_sentence) if invalid_lines.any?
      end

      def json_path(*elements)
        elements.join(".")
      end

      def key_violates_type?(object, key, *types)
        return false unless object.key?(key)

        types.all? { |t| !object.fetch(key).is_a?(t) }
      end
    end
  end
end
