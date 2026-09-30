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

module OpenIDConnect
  module Providers
    class SetAttributesService < BaseServices::SetAttributes
      private

      def set_default_attributes(*) # rubocop:disable Metrics/AbcSize
        model.change_by_system do
          model.issuer ||= OpenProject::StaticRouting::StaticUrlHelpers.new.root_url
          model.creator ||= user
          model.slug ||= "#{model.class.slug_fragment}-#{model.display_name.to_url}" if model.display_name
        end
      end

      def set_attributes(params)
        update_options(params.delete(:options)) if params.key?(:options)

        super

        update_string_list(:grant_types_supported, delimiter: " ")
        update_string_list(:group_regexes, delimiter: "\n")
        update_available_state
      end

      # This is a workaround for UI where users edit a single input field or text area, but are indeed editing
      # an array of items
      def update_string_list(attribute, delimiter:)
        return unless params[attribute].is_a? String

        model.public_send(
          "#{attribute}=",
          params[attribute].split(delimiter)
        )
      end

      def update_available_state
        model.change_by_system do
          model.available = model.configured?
        end
      end

      def update_options(options)
        options
          .select { |key, _| Saml::Provider.stored_attributes[:options].include?(key.to_s) }
          .each do |key, value|
          model.public_send(:"#{key}=", value)
        end
      end
    end
  end
end
