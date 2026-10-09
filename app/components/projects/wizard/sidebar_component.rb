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

module Projects
  module Wizard
    class SidebarComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def initialize(project:, custom_fields_by_section:, current_section:)
        super

        @project = project
        @custom_fields_by_section = custom_fields_by_section
        @current_section = current_section
      end

      private

      attr_reader :project, :custom_fields_by_section, :current_section

      def sections
        @sections ||= custom_fields_by_section.keys
      end

      def section_completed?(section)
        custom_fields_by_section[section]
          .reject(&:boolean?)
          .all? { |custom_field| project.typed_custom_value_for(custom_field).present? }
      end

      def section_current?(section)
        current_section&.id == section.id
      end
    end
  end
end
