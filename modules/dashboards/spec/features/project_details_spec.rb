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

require_relative '../support/pages/dashboard'

describe 'Project details widget on dashboard', js: true do
  let!(:version_cf) { create(:version_project_custom_field) }
  let!(:bool_cf) { create(:bool_project_custom_field) }
  let!(:user_cf) { create(:user_project_custom_field) }
  let!(:int_cf) { create(:int_project_custom_field) }
  let!(:float_cf) { create(:float_project_custom_field) }
  let!(:text_cf) { create(:text_project_custom_field) }
  let!(:string_cf) { create(:string_project_custom_field) }
  let!(:date_cf) { create(:date_project_custom_field) }

  let(:system_version) { create(:version, sharing: 'system') }

  let!(:project) do
    create(:project, members: { other_user => role }).tap do |p|
      p.send(int_cf.attribute_setter, 5)
      p.send(bool_cf.attribute_setter, true)
      p.send(version_cf.attribute_setter, system_version)
      p.send(float_cf.attribute_setter, 4.5)
      p.send(text_cf.attribute_setter, 'Some **long** text')
      p.send(string_cf.attribute_setter, 'Some small text')
      p.send(date_cf.attribute_setter, Date.current)
      p.send(user_cf.attribute_setter, other_user)

      p.save!(validate: false)
    end
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

  let(:role) do
    create(:role, permissions:)
  end

  let(:read_only_user) do
    create(:user, member_in_project: project, member_through_role: role)
  end
  let(:editing_user) do
    create(:user,
           member_in_project: project,
           member_with_permissions: editing_permissions,
           firstname: 'Cool',
           lastname: 'Guy')
  end
  let(:other_user) do
    create(:user,
           firstname: 'Other',
           lastname: 'User')
  end

  let(:dashboard_page) do
    Pages::Dashboard.new(project)
  end

  def add_project_details_widget
    dashboard_page.visit!
    dashboard_page.add_widget(1, 1, :within, "Project details")

    dashboard_page.expect_and_dismiss_toaster message: I18n.t('js.notice_successful_update')
  end

  def change_cf_value(cf, old_value, new_value)
    # Open description field
    cf.activate!
    sleep(0.1)

    # Change the value
    cf.expect_value(old_value)
    cf.set_value new_value
    cf.save! unless cf.field_type === 'create-autocompleter'

    # The edit field is toggled and the value saved.
    expect(page).to have_content(new_value)
    expect(page).to have_selector(cf.selector)
    expect(page).not_to have_selector(cf.input_selector)
  end

  before do
    login_as current_user
    add_project_details_widget
  end

  context 'without editing permissions' do
    let(:current_user) { read_only_user }

    it 'can add the widget, but not edit the custom fields' do
      # As the user lacks the manage_public_queries and save_queries permission, no other widget is present
      details_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

      within(details_widget.area) do
        # Expect values
        expect(page)
          .to have_content("#{int_cf.name}\n5")
        expect(page)
          .to have_content("#{bool_cf.name}\nyes")
        expect(page)
          .to have_content("#{version_cf.name}\n#{system_version.name}")
        expect(page)
          .to have_content("#{float_cf.name}\n4.5")
        expect(page)
          .to have_content("#{text_cf.name}\nSome long text")
        expect(page)
          .to have_content("#{string_cf.name}\nSome small text")
        expect(page)
          .to have_content("#{date_cf.name}\n#{Date.today.strftime('%m/%d/%Y')}")
        expect(page)
           .to have_content("#{user_cf.name}\n#{other_user.name.split.map(&:first).join}\n#{other_user.name}")

        # The fields are not editable
        field = EditField.new dashboard_page, bool_cf.attribute_name(:camel_case)
        field.expect_read_only
        field.activate! expect_open: false
      end
    end
  end

  context 'with editing permissions' do
    let(:current_user) { editing_user }

    it 'can edit the custom fields' do
      int_field = EditField.new dashboard_page, int_cf.attribute_name(:camel_case)
      change_cf_value int_field, "5", "3"

      string_field = EditField.new dashboard_page, string_cf.attribute_name(:camel_case)
      change_cf_value string_field, 'Some small text', 'Some new text'

      text_field = TextEditorField.new dashboard_page, text_cf.attribute_name(:camel_case)
      change_cf_value text_field, 'Some long text', 'Some very long text'

      user_field = SelectField.new dashboard_page, user_cf.attribute_name(:camel_case)
      change_cf_value user_field, other_user.name, editing_user.name
    end
  end

  context 'when project has Activity module enabled' do
    let(:current_user) { read_only_user }

    it 'has a "Project activity" entry in More menu linking to the project activity page' do
      details_widget = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')

      details_widget.expect_menu_item('Project details activity')

      details_widget.click_menu_item('Project details activity')
      expect(page).to have_current_path(project_activity_index_path(project), ignore_query: true)
      expect(page).to have_checked_field(id: 'event_types_project_attributes')
    end
  end
end
