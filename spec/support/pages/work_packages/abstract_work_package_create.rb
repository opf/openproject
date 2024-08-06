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
require "support/pages/work_packages/abstract_work_package"

module Pages
  class AbstractWorkPackageCreate < AbstractWorkPackage
    attr_reader :original_work_package,
                :project,
                :parent_work_package

    def initialize(original_work_package: nil, parent_work_package: nil, project: nil)
      # in case of copy, the original work package can be provided
      @project = project
      @original_work_package = original_work_package
      @parent_work_package = parent_work_package
    end

    def update_attributes(attribute_map)
      attribute_map.each do |label, value|
        work_package_field(label.downcase).set_value(value)
      end
    end

    def select_attribute(property, value)
      element = page.first(".inline-edit--container.#{property.downcase} select")

      element.select(value)
      element
    rescue Capybara::ExpectationNotMet
      nil
    end

    def expect_fully_loaded
      expect_angular_frontend_initialized
      expect(page).to have_css "#wp-new-inline-edit--field-subject", wait: 20
    end

    def save!
      scroll_to_and_click find(".button", text: I18n.t("js.button_save"))
    end

    def cancel!
      scroll_to_and_click find(".button", text: I18n.t("js.button_cancel"))
    end
  end
end
