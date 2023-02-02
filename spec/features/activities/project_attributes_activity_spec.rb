#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe 'Project attributes activities' do
  let(:user) do
    create(:user,
           member_in_project: project,
           member_with_permissions: %w[view_wiki_pages
                                       edit_wiki_pages
                                       view_wiki_edits])
  end
  let(:project) { create(:project, enabled_module_names: %w[activity]) }

  current_user { user }

  it 'tracks the project\'s activities', js: true do
    visit project_activity_index_path(project)

    check 'Project attributes'

    click_button 'Apply'

    within("li.project_attributes") do
      expect(page)
        .to have_link("Project: #{project.name}")

      expect(page).to have_selector(".hidden-for-sighted", text: 'Project attributes edited', visible: :hidden)
    end
  end
end
