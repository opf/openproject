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

require "support/pages/page"

module Pages
  module Projects
    module Settings
      class WorkPackageCustomFields < Pages::Page
        attr_accessor :project

        def initialize(project)
          super()

          self.project = project
        end

        def path
          "/projects/#{project.identifier}/settings/custom_fields"
        end

        def expect_active(custom_field)
          expect_field(custom_field, active: true)
        end

        def expect_inactive(custom_field)
          expect_field(custom_field, active: false)
        end

        def activate(custom_field)
          check custom_field.name
        end

        def expect_field(custom_field, active: true)
          expect(page)
            .to have_field(custom_field.name, checked: active)
        end

        def save!
          click_link_or_button "Save"
        end
      end
    end
  end
end
