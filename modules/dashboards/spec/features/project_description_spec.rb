#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

require_relative '../support/pages/dashboard'

describe 'Project description widget on dashboard', type: :feature, js: true do
  let(:project_description) { "Some text I like to write" }
  let!(:project) do
    FactoryBot.create :project, description: project_description
  end

  let(:permissions) do
    %i[view_dashboards
       manage_dashboards]
  end

  let(:editing_permissions) do
    %i[view_dashboards
       manage_dashboards
       edit_project]
  end

  let(:user) do
    FactoryBot.create(:user, member_in_project: project, member_with_permissions: permissions)
  end

  let(:second_user) do
    FactoryBot.create(:user, member_in_project: project, member_with_permissions: editing_permissions)
  end

  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end

  def add_project_description_widget
    dashboard_page.visit!
    dashboard_page.add_widget(1, 1, :within, "Project description")

    sleep(0.1)
  end

  context 'without editing permissions' do
    before do
      login_as user
      add_project_description_widget
    end

    it 'can add the widget, but not edit the description' do
      # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
      description_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

      within(description_widget.area) do
        # The description is visible
        expect(page)
          .to have_content(project_description)

        # The description is not editable
        field = TextEditorField.new dashboard_page, 'description'
        field.activate! expect_open: false
      end
    end
  end

  context 'with editing permissions' do
    before do
      login_as second_user
      add_project_description_widget
    end

    it 'can edit the description' do
      # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
      description_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

      within(description_widget.area) do
        # Open description field
        field = TextEditorField.new dashboard_page, 'description'
        field.activate!
        sleep(0.1)

        # Change the value
        field.expect_value(project_description)
        field.set_value 'A completely new description which is super cool.'
        field.save!

        # The edit field is toggled and the value saved.
        expect(page).to have_content('A completely new description which is super cool.')
        expect(page).to have_selector(field.selector)
        expect(page).not_to have_selector(field.input_selector)
      end

    end
  end

end
