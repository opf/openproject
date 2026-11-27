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

require_relative "select_edit_field"

class ProjectEditField < SelectField
  def autocompleter
    field_container
  end

  def search_for(query)
    search_autocomplete(autocompleter,
                        query:,
                        results_selector: ".ng-dropdown-panel-items")
  end

  def dropdown
    ng_find_dropdown(autocompleter, results_selector: ".ng-dropdown-panel-items")
  end

  def expect_option(name, workspace_badge: false)
    within(dropdown) do
      option = page.find(".ng-option", text: name)

      if workspace_badge
        expect(option).to have_octicon
        expect(option).to have_primer_text(workspace_badge, class: "description")
      else
        expect(option).to have_no_octicon
        expect(option).to have_no_primer_text(class: "description")
      end
    end
  end

  def clear_search
    ng_select_input(autocompleter).set("")
  end
end
