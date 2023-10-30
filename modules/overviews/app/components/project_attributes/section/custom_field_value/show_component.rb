#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module ProjectAttributes
  module Section
    module CustomFieldValue
      class ShowComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers

        def initialize(custom_field_value:)
          super

          @custom_field_value = custom_field_value
        end

        private

        def formated_value
          case @custom_field_value.custom_field.field_format
          when "text"
            ::OpenProject::TextFormatting::Renderer.format_text(@custom_field_value.typed_value)
          when "date"
            format_date(@custom_field_value.typed_value)
          else
            @custom_field_value.typed_value&.to_s
          end
        end
      end
    end
  end
end
