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

module Admin
  module Settings
    module UserCustomFieldSections
      class BuiltInAttributesController < ::Admin::SettingsController
        include OpTurbo::ComponentStream
        include Admin::Settings::UserCustomFields::ComponentStreams

        menu_item :user_custom_fields_settings

        before_action :set_section
        before_action :set_attribute_key

        def move
          @section.move_in_order(@key, params.expect(:move_to)&.to_sym)
          update_section_via_turbo_stream(user_custom_field_section: @section.reload)
          respond_with_turbo_streams
        end

        def drop # rubocop:disable Metrics/AbcSize
          new_section_id = params[:target_id]&.to_i
          return head :bad_request if new_section_id.nil?

          if @section.id == new_section_id
            @section.add_to_order(@key, position: params[:position]&.to_i)
            update_section_via_turbo_stream(user_custom_field_section: @section.reload)
          else
            new_section = UserCustomFieldSection.find(new_section_id)
            @section.remove_from_order(@key)
            new_section.add_to_order(@key, position: params[:position]&.to_i)
            update_section_via_turbo_stream(user_custom_field_section: @section.reload)
            update_section_via_turbo_stream(user_custom_field_section: new_section.reload)
          end

          respond_with_turbo_streams
        end

        private

        def set_section
          @section = UserCustomFieldSection.find(params.expect(:user_custom_field_section_id))
        end

        def set_attribute_key
          @key = params.expect(:key)
          head :unprocessable_entity unless UserCustomFieldSection::BUILT_IN_ATTRIBUTES.include?(@key)
        end
      end
    end
  end
end
