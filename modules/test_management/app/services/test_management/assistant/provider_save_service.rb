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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module TestManagement
  module Assistant
    class ProviderSaveService
      FORM_KEYS = %w[assistant_provider assistant_base_url assistant_model assistant_auth_style assistant_api_key
                     remove_api_key assistant_timeout assistant_max_tokens].freeze

      Result = Struct.new(:success, :provider, :errors, :verification, keyword_init: true) do
        def success? = success
      end

      attr_reader :provider

      def initialize(provider)
        @provider = provider
      end

      def call(form) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        form = form.to_h.stringify_keys
        merged, errors = ProviderConfig.apply(provider.new_record? ? {} : provider.settings, form.slice(*FORM_KEYS))
        provider.name = form["name"].to_s.strip if form.key?("name") || provider.new_record?
        provider.user_models = form["user_models"] if form.key?("user_models")
        provider.assign_settings(merged) if errors.empty?
        provider.validate
        errors += provider.errors.full_messages
        return failure(errors) if errors.any?

        if truthy?(form["verify_model"])
          verification = AI::ConnectionTest.new(provider.config).verify_model
          return failure([verification.message], verification) unless verification.ok?
        end

        save!(make_default: truthy?(form["make_default"]))
        Result.new(success: true, provider:, errors: [], verification:)
      end

      private

      def save!(make_default:)
        TestManagement::AssistantProvider.transaction do
          provider.save!
          others = TestManagement::AssistantProvider.where(is_default: true).where.not(id: provider.id)
          provider.make_default! if make_default || !others.exists?
        end
      end

      def failure(errors, verification = nil)
        Result.new(success: false, provider:, errors: errors.uniq, verification:)
      end

      def truthy?(value)
        ActiveModel::Type::Boolean.new.cast(value) == true
      end
    end
  end
end
