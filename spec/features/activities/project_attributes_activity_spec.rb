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
  let(:project) { create(:project, active: false, enabled_module_names: %w[activity]) }
  # more factories available in spec/factories/custom_field_factory.rb
  let!(:list_project_custom_field) { create(:list_project_custom_field) }
  let!(:version_project_custom_field) { create(:version_project_custom_field) }
  let!(:bool_project_custom_field) { create(:bool_project_custom_field) }
  let!(:user_project_custom_field) { create(:user_project_custom_field) }
  let!(:int_project_custom_field) { create(:int_project_custom_field) }
  let!(:float_project_custom_field) { create(:float_project_custom_field) }
  let!(:text_project_custom_field) { create(:text_project_custom_field) }
  let!(:string_project_custom_field) { create(:string_project_custom_field) }
  let!(:date_project_custom_field) { create(:date_project_custom_field) }

  current_user { user }

  it 'tracks the project\'s activities', js: true do
    new_project_attributes = {
      active: true,
      name: 'a new project name',
      description: 'a new project description',
      string_project_custom_field.attribute_name => 'a new text custom field value'
    }
    project.update(new_project_attributes)

    visit project_activity_index_path(project)

    check 'Project attributes'

    click_button 'Apply'

    within("li.op-project-activity-list--item", match: :first) do
      expect(page)
        .to have_link("Project: #{project.name}")

      # expect each attribute to appear
      ### own fields
      # name
      # description
      # public
      # parent
      # identifier
      # active (project archived or active)
      # template
      ### custom fields
      # Text CF
      # Long text CF
      # Integer CF
      # Float CF
      # Boolean CF
      # Version CF
      # User CF
      # Date CF
      # List CF

      # or
      expect(page).to have_text('Project unarchived')
      # expect(page).to have_text('Project name changed from (old name) to (new name)')
      # expect(page).to have_text('Description changed (Details)')
      # expect(page).to have_text('Project visibility changed to (new visibility)')
      # expect(page).to have_text('Project parent changed to (new parent)')
      # expect(page).to have_text('Identifier changed to (new identifier)') # probably not needed
      # expect(page).to have_text('Template: Project marked as template')
      # # or
      # expect(page).to have_text('Template: Project un-marked as template')

      # expect(page).to have_text('') # list
      # expect(page).to have_text('') # version
      # expect(page).to have_text('') # bool
      # expect(page).to have_text('') # user
      # expect(page).to have_text('') # int
      # expect(page).to have_text('') # float
      # expect(page).to have_text('a new text custom field value')
      # expect(page).to have_text('') # string
      # expect(page).to have_text('') # date
    end
  end
end
