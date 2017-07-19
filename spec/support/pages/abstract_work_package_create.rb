#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'support/pages/page'
require 'support/pages/abstract_work_package'

module Pages
  class AbstractWorkPackageCreate < AbstractWorkPackage
    attr_reader :original_work_package,
                :project,
                :parent_work_package

    def initialize(original_work_package: nil, parent_work_package: nil)
      # in case of copy, the original work package can be provided
      @original_work_package = original_work_package
      @parent_work_package = parent_work_package
    end

    def expect_heading(type=nil)
      if type.nil?
        expect(page).to have_selector('h2', text: I18n.t('js.work_packages.create.header_no_type'))

      elsif parent_work_package
        expect(page).to have_selector('h2',
                                      text: I18n.t('js.work_packages.create.header_with_parent',
                                                   type: type,
                                                   parent_type: parent_work_package.type,
                                                   id: parent_work_package.id))
      else
        expect(page).to have_selector('h2', text: I18n.t('js.work_packages.create.header',
                                                         type: type))
      end
    end

    def update_attributes(attribute_map)
      # Only designed for text fields and selects for now
      attribute_map.each do |label, value|
        select_attribute(label, value) || fill_in(label, with: value)
      end
    end

    def select_attribute(property, value)
      element = page.first(".wp-edit-field.#{property.downcase} select")

      if element
        element.select(value)
        element
      else
        nil
      end
    end

    def expect_fully_loaded
      expect(page).to have_selector '#wp-new-inline-edit--field-subject'
    end

    def save!
      click_button I18n.t('js.button_save')
    end
  end
end
