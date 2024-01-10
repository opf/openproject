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
require_relative 'shared_context'
require_relative 'overview_page'

RSpec.describe 'Edit project custom fields on project overview page', :js, :with_cuprite do
  include_context 'with seeded projects, members and project custom fields'

  let(:overview_page) { OverviewPage.new(project) }

  before do
    login_as admin
  end

  describe 'with enabled project attributes feature', with_flag: { project_attributes: true } do
    describe 'with sufficient permissions' do
      describe 'enables editing of project custom field values via dialog' do
        it 'opens a dialog showing inputs for project custom fields of a specific section' do
          overview_page.visit_page

          overview_page.open_edit_dialog_for_section(section_for_input_fields)

          expect(page).to have_css("modal-dialog#edit-project-attributes-dialog-#{section_for_input_fields.id}")
        end

        it 'renders the dialog body asynchronically' do
          overview_page.visit_page

          expect(page).to have_no_css('#project-custom-fields-sections-edit-dialog-component', visible: :all)

          overview_page.open_edit_dialog_for_section(section_for_input_fields)

          expect(page).to have_css('#project-custom-fields-sections-edit-dialog-component', visible: :visible)
        end

        it 'can be closed via close icon or cancel button' do
          overview_page.visit_page

          overview_page.open_edit_dialog_for_section(section_for_input_fields)

          within("modal-dialog#edit-project-attributes-dialog-#{section_for_input_fields.id}") do
            page.find(".close-button").click
          end

          expect(page).to have_no_css("modal-dialog#edit-project-attributes-dialog-#{section_for_input_fields.id}")

          overview_page.open_edit_dialog_for_section(section_for_input_fields)

          within("modal-dialog#edit-project-attributes-dialog-#{section_for_input_fields.id}") do
            click_link_or_button 'Cancel'
          end

          expect(page).to have_no_css("modal-dialog#edit-project-attributes-dialog-#{section_for_input_fields.id}")
        end

        it 'shows only the project custom fields of the specific section within the dialog' do
          overview_page.visit_page

          overview_page.open_edit_dialog_for_section(section_for_input_fields)

          overview_page.within_edit_dialog_for_section(section_for_input_fields) do
            (input_fields + select_fields + multi_select_fields).each do |project_custom_field|
              if input_fields.include?(project_custom_field)
                expect(page).to have_content(project_custom_field.name)
              else
                expect(page).to have_no_content(project_custom_field.name)
              end
            end
          end

          overview_page.close_edit_dialog_for_section(section_for_input_fields)

          overview_page.open_edit_dialog_for_section(section_for_select_fields)

          overview_page.within_edit_dialog_for_section(section_for_select_fields) do
            (input_fields + select_fields + multi_select_fields).each do |project_custom_field|
              if select_fields.include?(project_custom_field)
                expect(page).to have_content(project_custom_field.name)
              else
                expect(page).to have_no_content(project_custom_field.name)
              end
            end
          end

          overview_page.close_edit_dialog_for_section(section_for_select_fields)

          overview_page.open_edit_dialog_for_section(section_for_multi_select_fields)

          overview_page.within_edit_dialog_for_section(section_for_multi_select_fields) do
            (input_fields + select_fields + multi_select_fields).each do |project_custom_field|
              if multi_select_fields.include?(project_custom_field)
                expect(page).to have_content(project_custom_field.name)
              else
                expect(page).to have_no_content(project_custom_field.name)
              end
            end
          end
        end

        it 'shows the inputs in the correct order defined by the position of project custom field in a section' do
          overview_page.visit_page

          overview_page.open_edit_dialog_for_section(section_for_input_fields)

          overview_page.within_edit_dialog_for_section(section_for_input_fields) do
            fields = page.all('.op-project-custom-field-input-container')

            expect(fields[0].text).to include('Boolean field')
            expect(fields[1].text).to include('String field')
            expect(fields[2].text).to include('Integer field')
            expect(fields[3].text).to include('Float field')
            expect(fields[4].text).to include('Date field')
            expect(fields[5].text).to include('Text field')
          end

          overview_page.close_edit_dialog_for_section(section_for_input_fields)

          boolean_project_custom_field.move_to_bottom

          overview_page.open_edit_dialog_for_section(section_for_input_fields)

          overview_page.within_edit_dialog_for_section(section_for_input_fields) do
            fields = page.all('.op-project-custom-field-input-container')

            expect(fields[0].text).to include('String field')
            expect(fields[1].text).to include('Integer field')
            expect(fields[2].text).to include('Float field')
            expect(fields[3].text).to include('Date field')
            expect(fields[4].text).to include('Text field')
            expect(fields[5].text).to include('Boolean field')
          end
        end
      end
    end
  end
end
