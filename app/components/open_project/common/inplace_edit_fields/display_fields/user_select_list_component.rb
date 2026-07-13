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

module OpenProject
  module Common
    module InplaceEditFields
      module DisplayFields
        class UserSelectListComponent < SelectListComponent
          include CustomFieldsHelper

          attr_reader :model, :attribute, :writable

          def formatted_custom_field_values
            return @formatted_custom_field_values if defined?(@formatted_custom_field_values)

            cf_values = custom_field_values

            users = cf_values.filter_map(&:typed_value)

            @formatted_custom_field_values = if custom_field.multi_value?
                                               flex_layout do |avatar_container|
                                                 users.each do |user|
                                                   avatar_container.with_row do
                                                     render_avatar(user)
                                                   end
                                                 end
                                               end
                                             else
                                               render_avatar(users.first)
                                             end
          end

          private

          def render_avatar(user)
            return unless user

            render(::Users::AvatarComponent.new(user:, size: :mini))
          end
        end
      end
    end
  end
end
