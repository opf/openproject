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

module Settings
  module UserCustomFieldSections
    class DialogBodyFormComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(user_custom_field_section: UserCustomFieldSection.new)
        super

        @user_custom_field_section = user_custom_field_section
      end

      private

      def wrapper_uniq_by
        @user_custom_field_section.id
      end

      def form_config
        {
          model: @user_custom_field_section,
          method: @user_custom_field_section.persisted? ? :put : :post,
          url: if @user_custom_field_section.persisted?
                 admin_settings_user_custom_field_section_path(@user_custom_field_section)
               else
                 admin_settings_user_custom_field_sections_path
               end,
          data: { turbo_stream: true }
        }
      end
    end
  end
end
