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
  class Activity < Pages::Page
    def path
      activity_index_path
    end

    def show_details
      within "#activity_menu" do
        check "Project details"

        click_on "Apply"
      end
    end

    def within_journal(number:, &)
      within("li.op-activity-list--item:nth-child(#{number})", &)
    end

    def expect_link_to_project(project)
      expect(page).to have_link("Project: #{project.name}", href: project_path(project))
    end

    def expect_activity(text)
      expect(page).to have_css("li", text:)
    end

    def expect_no_activity(text)
      expect(page).to have_no_css("li", text:)
    end
  end
end
