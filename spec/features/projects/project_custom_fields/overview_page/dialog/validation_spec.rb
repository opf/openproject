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
require_relative '../shared_context'

RSpec.describe 'Edit project custom fields on project overview page', :js do
  include_context 'with seeded projects, members and project custom fields'

  let(:overview_page) { Pages::Projects::Show.new(project) }

  before do
    login_as member_with_project_edit_permissions
    overview_page.visit_page
  end

  describe 'with correct validation behaviour' do
    describe 'after validation' do
      let(:section) { section_for_input_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      it 'keeps showing only activated custom fields (tricky regression)' do
        custom_field = string_project_custom_field
        custom_field.update!(is_required: true)
        field = FormFields::Primerized::InputField.new(custom_field)

        overview_page.open_edit_dialog_for_section(section)

        dialog.within_async_content do
          containers = dialog.input_containers

          expect(containers[0].text).to include('Boolean field')
          expect(containers[1].text).to include('String field')
          expect(containers[2].text).to include('Integer field')
          expect(containers[3].text).to include('Float field')
          expect(containers[4].text).to include('Date field')
          expect(containers[5].text).to include('Text field')

          expect(page).to have_no_text(boolean_project_custom_field_activated_in_other_project.name)
        end

        field.fill_in(with: '') # this will trigger the validation

        dialog.submit

        field.expect_error(I18n.t('activerecord.errors.messages.blank'))

        dialog.within_async_content do
          containers = dialog.input_containers

          expect(containers[0].text).to include('Boolean field')
          expect(containers[1].text).to include('String field')
          expect(containers[2].text).to include('Integer field')
          expect(containers[3].text).to include('Float field')
          expect(containers[4].text).to include('Date field')
          expect(containers[5].text).to include('Text field')

          expect(page).to have_no_text(boolean_project_custom_field_activated_in_other_project.name)
        end
      end
    end

    describe 'with input fields' do
      let(:section) { section_for_input_fields }
      let(:dialog) { Components::Projects::ProjectCustomFields::EditDialog.new(project, section) }

      shared_examples 'a custom field input' do
        it 'shows an error if the value is invalid' do
          custom_field.update!(is_required: true)
          custom_field.custom_values.destroy_all

          overview_page.open_edit_dialog_for_section(section)

          dialog.submit

          field.expect_error(I18n.t('activerecord.errors.messages.blank'))
        end
      end

      # boolean CFs can not be validated

      describe 'with string CF' do
        let(:custom_field) { string_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like 'a custom field input'

        it 'shows an error if the value is too long' do
          custom_field.update!(max_length: 3)

          overview_page.open_edit_dialog_for_section(section)

          field.fill_in(with: 'Foooo')

          dialog.submit

          field.expect_error(I18n.t('activerecord.errors.messages.too_long', count: 3))
        end

        it 'shows an error if the value is too short' do
          custom_field.update!(min_length: 3, max_length: 5)

          overview_page.open_edit_dialog_for_section(section)

          field.fill_in(with: 'Fo')

          dialog.submit

          field.expect_error(I18n.t('activerecord.errors.messages.too_short', count: 3))
        end

        it 'shows an error if the value does not match the regex' do
          custom_field.update!(regexp: '^[A-Z]+$')

          overview_page.open_edit_dialog_for_section(section)

          field.fill_in(with: 'foo')

          dialog.submit

          field.expect_error(I18n.t('activerecord.errors.messages.invalid'))
        end
      end

      describe 'with integer CF' do
        let(:custom_field) { integer_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like 'a custom field input'

        it 'shows an error if the value is too long' do
          custom_field.update!(max_length: 2)

          overview_page.open_edit_dialog_for_section(section)

          field.fill_in(with: '111')

          dialog.submit

          field.expect_error(I18n.t('activerecord.errors.messages.too_long', count: 2))
        end

        it 'shows an error if the value is too short' do
          custom_field.update!(min_length: 2, max_length: 5)

          overview_page.open_edit_dialog_for_section(section)

          field.fill_in(with: '1')

          dialog.submit

          field.expect_error(I18n.t('activerecord.errors.messages.too_short', count: 2))
        end
      end

      describe 'with float CF' do
        let(:custom_field) { float_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like 'a custom field input'

        it 'shows an error if the value is too long' do
          custom_field.update!(max_length: 4)

          overview_page.open_edit_dialog_for_section(section)

          field.fill_in(with: '1111.1')

          dialog.submit

          field.expect_error(I18n.t('activerecord.errors.messages.too_long', count: 4))
        end

        it 'shows an error if the value is too short' do
          custom_field.update!(min_length: 4, max_length: 5)

          overview_page.open_edit_dialog_for_section(section)

          field.fill_in(with: '1.1')

          dialog.submit

          field.expect_error(I18n.t('activerecord.errors.messages.too_short', count: 4))
        end
      end

      describe 'with date CF' do
        let(:custom_field) { date_project_custom_field }
        let(:field) { FormFields::Primerized::InputField.new(custom_field) }

        it_behaves_like 'a custom field input'
      end

      describe 'with text CF' do
        let(:custom_field) { text_project_custom_field }
        let(:field) { FormFields::Primerized::EditorFormField.new(custom_field) }

        it_behaves_like 'a custom field input'

        it 'shows an error if the value is too long' do
          custom_field.update!(max_length: 3)

          overview_page.open_edit_dialog_for_section(section)

          field.set_value('Foooo')

          dialog.submit

          field.expect_error(I18n.t('activerecord.errors.messages.too_long', count: 3))
        end

        it 'shows an error if the value is too short' do
          custom_field.update!(min_length: 3, max_length: 5)

          overview_page.open_edit_dialog_for_section(section)

          field.set_value('Fo')

          dialog.submit

          field.expect_error(I18n.t('activerecord.errors.messages.too_short', count: 3))
        end
      end
    end
  end
end
