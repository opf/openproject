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
  module Departments
    class BlankslateComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers

      def call
        render(Primer::Beta::Blankslate.new(border: false)) do |component|
          component.with_visual_icon(icon: :people, size: :medium)
          component.with_heading(tag: :h2) { t("departments.blankslate.heading") }
          component.with_description { t("departments.blankslate.description") }
          component.with_primary_action(
            href: new_department_admin_departments_path,
            scheme: :primary,
            data: { turbo_frame: Admin::Departments::DetailComponent.wrapper_key }
          ) do |button|
            button.with_leading_visual_icon(icon: :plus)
            t("departments.blankslate.add_button")
          end
        end
      end
    end
  end
end
