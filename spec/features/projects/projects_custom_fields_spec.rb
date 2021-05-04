#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Projects custom fields', type: :feature, js: true do
  shared_let(:current_user) { FactoryBot.create(:admin) }
  shared_let(:project) { FactoryBot.create(:project, name: 'Foo project', identifier: 'foo-project') }
  let(:name_field) { ::FormFields::InputFormField.new :name }
  let(:identifier) { "[data-qa-field-name='customField#{custom_field.id}'] input[type=checkbox]" }

  before do
    login_as current_user
  end

  describe 'with version CF' do
    let!(:custom_field) do
      FactoryBot.create(:version_project_custom_field)
    end
    let(:cf_field) { ::FormFields::SelectFormField.new custom_field }

    scenario 'allows creating a new project (regression #29099)' do
      visit new_project_path

      name_field.set_value 'My project name'

      find('.form--fieldset-legend a', text: 'ADVANCED SETTINGS').click

      cf_field.expect_visible

      click_button 'Save'

      expect(page).to have_current_path /\/projects\/my-project-name\/?/
    end
  end

  describe 'with default values' do
    let!(:default_int_custom_field) do
      FactoryBot.create(:int_project_custom_field, default_value: 123)
    end
    let!(:default_string_custom_field) do
      FactoryBot.create(:string_project_custom_field, default_value: 'lorem')
    end
    let!(:no_default_string_custom_field) do
      FactoryBot.create(:string_project_custom_field)
    end

    let(:name_field) { ::FormFields::InputFormField.new :name }
    let(:default_int_field) { ::FormFields::InputFormField.new default_int_custom_field }
    let(:default_string_field) { ::FormFields::InputFormField.new default_string_custom_field }
    let(:no_default_string_field) { ::FormFields::InputFormField.new no_default_string_custom_field }

    scenario 'sets the default values on custom fields and allows overwriting them' do
      visit new_project_path

      name_field.set_value 'My project name'
      find('.form--fieldset-legend a', text: 'ADVANCED SETTINGS').click

      default_int_field.expect_value default_int_custom_field.default_value.to_s
      default_string_field.expect_value default_string_custom_field.default_value.to_s
      no_default_string_field.expect_value ''

      default_string_field.set_value 'Overwritten'

      click_button 'Save'

      expect(page).to have_current_path /\/projects\/my-project-name\/?/
      created_project = Project.last

      visit settings_project_path(created_project)

      default_int_field.expect_value default_int_custom_field.default_value.to_s
      default_string_field.expect_value 'Overwritten'
      no_default_string_field.expect_value ''
    end
  end

  describe 'with long text CF' do
    let!(:custom_field) do
      FactoryBot.create(:text_project_custom_field)
    end
    let(:editor) { ::Components::WysiwygEditor.new "[data-qa-field-name='customField#{custom_field.id}']" }

    scenario 'allows settings the project boolean CF (regression #26313)' do
      visit settings_generic_project_path(project.id)

      # expect CF, description and status description ckeditor
      expect(page).to have_selector('.op-ckeditor--wrapper', count: 3)

      # single hash autocomplete
      editor.insert_link 'http://example.org/link with spaces'

      sleep 2

      # Save project settings
      click_on 'Save'

      expect(page).to have_text I18n.t('js.notice_successful_update')

      project.reload
      cv = project.custom_values.find_by(custom_field_id: custom_field.id).value

      expect(cv).to include '[http://example.org/link with spaces](http://example.org/link%20with%20spaces)'
      expect(page).to have_selector('a[href="http://example.org/link with spaces"]')
    end
  end

  describe 'with boolean CF' do
    let!(:custom_field) do
      FactoryBot.create(:bool_project_custom_field)
    end

    scenario 'allows settings the project boolean CF (regression #26313)' do
      visit settings_generic_project_path(project.id)
      field = page.find(identifier)
      expect(field).not_to be_checked

      field.check

      click_on 'Save'
      expect(page).to have_text I18n.t(:notice_successful_update)

      field = page.find(identifier)
      expect(field).to be_checked

    end
  end
end
