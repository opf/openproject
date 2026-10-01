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

module Users
  module Profile
    # Builds the ordered list of renderable SectionAttribute objects for a section,
    # filtered by per-attribute visibility (mirroring API::V3::Users::UserRepresenter)
    # and by value presence. Built-in keys resolve to user attributes; other keys
    # resolve to the section's custom fields.
    class SectionAttributes
      include Redmine::I18n

      def self.for(section:, user:, current_user:)
        new(section:, user:, current_user:).call
      end

      def initialize(section:, user:, current_user:)
        @section = section
        @user = user
        @current_user = current_user
      end

      def call
        cf_by_key = @section.custom_fields_by_key

        @section.attribute_order.filter_map do |key|
          if UserCustomFieldSection::BUILT_IN_ATTRIBUTES.include?(key)
            built_in_attribute(key)
          elsif (custom_field = cf_by_key[key])
            custom_field_attribute(custom_field)
          end
        end
      end

      private

      def built_in_attribute(key)
        return unless built_in_visible?(key)

        value = built_in_value(key)
        return if value.blank?

        SectionAttribute.new(label: User.human_attribute_name(key), value:, icon: built_in_icon(key))
      end

      def built_in_icon(key)
        :briefcase if key == "department"
      end

      def custom_field_attribute(custom_field)
        return unless custom_field.visible?(@current_user)

        value = @user.formatted_custom_value_for(custom_field)
        return if value.blank?

        SectionAttribute.new(label: custom_field.name, value:)
      end

      def built_in_value(key)
        case key
        when "language"
          @user.language.presence && translate_language(@user.language).first
        when "department"
          @user.department&.name
        else
          @user.public_send(key)
        end
      end

      def built_in_visible?(key)
        case key
        when "mail"
          can_view_email? || can_manage?
        when "department"
          true
        else
          can_manage?
        end
      end

      def can_manage?
        @current_user.allowed_globally?(:manage_user) ||
          @current_user.allowed_globally?(:create_user) ||
          @current_user == @user
      end

      def can_view_email?
        @current_user.allowed_globally?(:view_user_email)
      end
    end
  end
end
