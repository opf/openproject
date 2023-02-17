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
  let(:parent_project) { create(:project, name: 'parent') }
  let(:project) { create(:project, parent: parent_project, active: false, enabled_module_names: %w[activity]) }
  let!(:list_project_custom_field) { create(:list_project_custom_field) }
  let!(:version_project_custom_field) { create(:version_project_custom_field) }
  let!(:bool_project_custom_field) { create(:bool_project_custom_field) }
  let!(:user_project_custom_field) { create(:user_project_custom_field) }
  let!(:int_project_custom_field) { create(:int_project_custom_field) }
  let!(:float_project_custom_field) { create(:float_project_custom_field) }
  let!(:text_project_custom_field) { create(:text_project_custom_field) }
  let!(:string_project_custom_field) { create(:string_project_custom_field) }
  let!(:date_project_custom_field) { create(:date_project_custom_field) }

  let(:next_version) { create(:version, project:, name: 'Turfu 2.0') }

  current_user { user }

  it 'tracks the project\'s activities', js: true do
    previous_project_attributes = project.attributes.dup
    new_project_attributes = {
      name: 'a new project name',
      description: 'a new project description',
      public: true,
      parent: nil,
      identifier: 'a-new-project-name',
      active: true,
      templated: true,

      list_project_custom_field.attribute_name => list_project_custom_field.possible_values.first.id,
      version_project_custom_field.attribute_name => next_version.id,
      bool_project_custom_field.attribute_name => true,
      user_project_custom_field.attribute_name => current_user.id,
      int_project_custom_field.attribute_name => 42,
      float_project_custom_field.attribute_name => 3.14159,
      text_project_custom_field.attribute_name => 'a new text CF value',
      string_project_custom_field.attribute_name => 'a new string CF value',
      date_project_custom_field.attribute_name => Date.new(2023, 1, 31)
    }
    project.update!(new_project_attributes)

    visit project_activity_index_path(project)

    check 'Project attributes'

    click_button 'Apply'

    within("li.op-project-activity-list--item", match: :first) do
      expect(page)
        .to have_link("Project: #{project.name}")

      # own fields
      expect(page).to have_selector('li', text: "Name changed from #{previous_project_attributes['name']} to #{project.name}")
      expect(page).to have_selector('li', text: 'Description set (Details)')
      expect(page).to have_selector('li', text: 'Visibility set to public')
      expect(page).to have_selector('li', text: "Subproject of deleted (#{parent_project.name})")
      expect(page).to have_selector('li', text: 'Project unarchived')
      expect(page).to have_selector('li', text: "Identifier changed from #{previous_project_attributes['identifier']} " \
                                                "to #{project.identifier}")
      expect(page).to have_selector('li', text: 'Project marked as template')

      # custom fields
      expect(page).to have_selector('li', text: "#{list_project_custom_field.name} " \
                                                "set to #{project.send(list_project_custom_field.attribute_getter)}")
      expect(page).to have_selector('li', text: "#{version_project_custom_field.name} set to #{next_version.name}")
      expect(page).to have_selector('li', text: "#{bool_project_custom_field.name} set to Yes")
      expect(page).to have_selector('li', text: "#{user_project_custom_field.name} set to #{current_user.name}")
      expect(page).to have_selector('li', text: "#{int_project_custom_field.name} set to 42")
      expect(page).to have_selector('li', text: "#{float_project_custom_field.name} set to 3.14159")
      expect(page).to have_selector('li', text: "#{text_project_custom_field.name} set to\na new text CF value")
      expect(page).to have_selector('li', text: "#{string_project_custom_field.name} set to a new string CF value")
      expect(page).to have_selector('li', text: "#{date_project_custom_field.name} set to 01/31/2023")
    end
  end
end
