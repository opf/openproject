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

module ProjectCustomFields
  module Sections
    module ProjectCustomFields
      class ShowComponent < ApplicationComponent
        include ApplicationHelper
        include CustomFieldsHelper
        include OpPrimer::ComponentHelpers

        def initialize(project_custom_field:, project_custom_field_values:)
          super

          @project_custom_field = project_custom_field
          @project_custom_field_values = project_custom_field_values
        end

        private

        def not_set?
          @project_custom_field_values.empty? || @project_custom_field_values.all? { |cf_value| cf_value.value.blank? }
        end

        def render_value
          case @project_custom_field.field_format
          when "link"
            render_link
          when "text"
            render_long_text
          when "user"
            render_user
          else
            render(Primer::Beta::Text.new) do
              @project_custom_field_values&.map do |cf_value|
                format_value(cf_value.value, @project_custom_field)
              end&.join(", ")
            end
          end
        end

        def render_long_text
          render OpenProject::Common::AttributeComponent.new("dialog-cf-#{@project_custom_field.id}",
                                                             @project_custom_field.name,
                                                             @project_custom_field_values&.first&.value,
                                                             lines: 3)
        end

        def render_user
          if @project_custom_field.multi_value?
            flex_layout do |avatar_container|
              @project_custom_field_values&.each do |cf_value|
                avatar_container.with_row do
                  render_avatar(cf_value.typed_value)
                end
              end
            end
          else
            render_avatar(@project_custom_field_values&.first&.typed_value)
          end
        end

        def render_avatar(user)
          render(Users::AvatarComponent.new(user:, size: :mini))
        end

        def render_link
          href = @project_custom_field_values&.first&.value
          link = Addressable::URI.parse(href)
          return href unless link

          target = link.host == Setting.host_without_protocol ? "_top" : "_blank"
          render(Primer::Beta::Link.new(href:, rel: "noopener noreferrer", target:)) do
            href
          end
        end
      end
    end
  end
end
