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

require "support/pages/page"

module Pages
  module Projects
    class Settings < Pages::Page
      attr_accessor :project

      def initialize(project)
        super()

        self.project = project
      end

      def visit_tab!(name)
        visit "/projects/#{project.identifier}/settings/#{name}"
      end

      # only notice is used as opposed to op-toast
      def expect_toast(message:, type: :success)
        expect(page).to have_css(".op-toast.-#{type}", text: message, wait: 10)
      end

      def expect_type_active(type)
        expect_type(type, true)
      end

      def expect_type_inactive(type)
        expect_type(type, false)
      end

      def expect_type(type, active = true)
        expect(page)
          .to have_field("project_planning_element_type_ids_#{type.id}", checked: active)
      end

      def expect_wp_custom_field_active(custom_field)
        expect_wp_custom_field(custom_field, true)
      end

      def expect_wp_custom_field_inactive(custom_field)
        expect_wp_custom_field(custom_field, false)
      end

      def activate_wp_custom_field(custom_field)
        check custom_field.name
      end

      def save!
        click_button "Save"
      end

      def expect_wp_custom_field(custom_field, active = true)
        expect(page)
          .to have_field(custom_field.name, checked: active)
      end

      def fieldset_label
        find "fieldset#project_issue_custom_fields label"
      end

      private

      def toast_type
        :rails
      end

      def path
        project_settings_general_path(project)
      end
    end
  end
end
