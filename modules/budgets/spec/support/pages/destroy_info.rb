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
  class DestroyInfo < Page
    attr_accessor :budget

    def initialize(budget)
      self.budget = budget
    end

    def expect_loaded
      expect(page)
        .to have_content("#{I18n.t(:button_delete)} #{I18n.t(:label_budget_id, id: budget.id)}: #{budget.subject}")
    end

    def expect_reassign_option
      expect(page)
        .to have_field("todo_reassign")
    end

    def expect_no_reassign_option
      expect(page)
        .to have_no_field("todo_reassign")
    end

    def select_reassign_option(budget_name)
      select(budget_name, from: "reassign_to_id")
    end

    def expect_delete_option
      expect(page)
        .to have_field("todo_delete")
    end

    def select_delete_option
      choose("todo_delete")
    end

    def delete
      click_button "Apply"
    end

    def path
      destroy_info_budget_path(budget)
    end
  end
end
