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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_relative "shared_context"

RSpec.describe "Edit project custom fields on project overview page", "attribute help texts", :js do
  include_context "with seeded projects, members and project custom fields"
  include API::V3::Utilities::PathHelper

  let(:overview_page) { Pages::Projects::Show.new(project) }

  before do
    login_as member_with_project_attributes_edit_permissions
    overview_page.visit_page
  end

  context "for input fields section" do
    context "without attribute help texts defined" do
      it "shows field labels without help text link" do
        input_fields.each do |custom_field|
          field = if custom_field == text_project_custom_field
                    overview_page.open_modal_for_custom_field(custom_field)
                  else
                    overview_page.open_inplace_edit_field_for_custom_field(custom_field)
                  end
          field.expect_field_label_without_help_text custom_field.name
          field.close
        end
      end
    end

    context "with attribute help texts defined" do
      let!(:boolean_help_text) { create(:project_help_text, attribute_name: boolean_project_custom_field.attribute_name) }
      let!(:date_help_text)    { create(:project_help_text, attribute_name: date_project_custom_field.attribute_name) }
      let!(:float_help_text)   { create(:project_help_text, attribute_name: float_project_custom_field.attribute_name) }
      let!(:integer_help_text) { create(:project_help_text, attribute_name: integer_project_custom_field.attribute_name) }
      let!(:link_help_text)    { create(:project_help_text, attribute_name: link_project_custom_field.attribute_name) }
      let!(:string_help_text)  { create(:project_help_text, attribute_name: string_project_custom_field.attribute_name) }
      let!(:text_help_text)    { create(:project_help_text, attribute_name: text_project_custom_field.attribute_name) }

      it "shows field labels with help text link" do
        input_fields.each do |custom_field|
          field = if custom_field == text_project_custom_field
                    overview_page.open_modal_for_custom_field(custom_field)
                  else
                    overview_page.open_inplace_edit_field_for_custom_field(custom_field)
                  end
          field.expect_field_label_with_help_text custom_field.name
          field.close
        end
      end

      context "without attachments" do
        it "shows help text modal on clicking help text link" do
          field = overview_page.open_inplace_edit_field_for_custom_field(date_project_custom_field)

          field.click_help_text_link_for_label "Date field"

          expect(page).to have_modal "Date field"
          within_modal "Date field" do
            expect(page).to have_text "Attribute help text"
            expect(page).to have_no_heading "Attachments"

            click_on "Close"
          end
          expect(page).to have_no_modal "Date field"
        end
      end

      context "with attachments" do
        let!(:attachments) { create_list(:attachment, 2, container: integer_help_text) }

        it "shows help text modal, including attachments, on clicking help text link" do
          field = overview_page.open_inplace_edit_field_for_custom_field(integer_project_custom_field)

          field.click_help_text_link_for_label "Integer field"
          expect(page).to have_modal "Integer field"
          within_modal "Integer field" do
            expect(page).to have_text "Attribute help text"

            expect(page).to have_heading "Attachments"
            expect(page).to have_list_item count: attachments.count
            expect(page).to have_list_item text: attachments.first.filename
            expect(page).to have_list_item text: attachments.second.filename

            attachment_window = window_opened_by do
              click_on attachments.first.filename
            end
            within_window(attachment_window) do
              expect(page).to have_current_path api_v3_paths.attachment_content(attachments.first.id)
              expect(page).to have_text "test content"
            end
            attachment_window.close

            click_on "Close"
          end
          expect(page).to have_no_modal "Integer field"
        end
      end
    end
  end

  context "for select fields section" do
    context "without attribute help texts defined" do
      it "shows field labels without help text link" do
        select_fields.each do |custom_field|
          field = overview_page.open_inplace_edit_field_for_custom_field(custom_field)
          field.expect_field_label_without_help_text custom_field.name
          field.close
        end
      end
    end

    context "with attribute help texts defined" do
      let!(:list_help_text)    { create(:project_help_text, attribute_name: list_project_custom_field.attribute_name) }
      let!(:version_help_text) { create(:project_help_text, attribute_name: version_project_custom_field.attribute_name) }
      let!(:user_help_text)    { create(:project_help_text, attribute_name: user_project_custom_field.attribute_name) }

      it "shows field labels with help text link" do
        select_fields.each do |custom_field|
          field = overview_page.open_inplace_edit_field_for_custom_field(custom_field)
          field.expect_field_label_with_help_text custom_field.name
          field.close
        end
      end

      it "shows help text modal on clicking help text link" do
        field = overview_page.open_inplace_edit_field_for_custom_field(user_project_custom_field)

        field.click_help_text_link_for_label "User field"

        expect(page).to have_modal "User field"
        within_modal "User field" do
          expect(page).to have_text "Attribute help text"

          click_on "Close"
        end
        expect(page).to have_no_modal "User field"
      end
    end
  end

  context "for multi select fields" do
    context "without attribute help texts defined" do
      it "shows field labels without help text link" do
        multi_select_fields.each do |custom_field|
          field = overview_page.open_inplace_edit_field_for_custom_field(custom_field)
          field.expect_field_label_without_help_text custom_field.name
          field.close
        end
      end
    end

    context "with attribute help texts defined" do
      let!(:multi_list_help_text) do
        create(:project_help_text, attribute_name: multi_list_project_custom_field.attribute_name)
      end
      let!(:multi_version_help_text) do
        create(:project_help_text, attribute_name: multi_version_project_custom_field.attribute_name)
      end
      let!(:multi_user_help_text) do
        create(:project_help_text, attribute_name: multi_user_project_custom_field.attribute_name)
      end

      it "shows field labels with help text link" do
        multi_select_fields.each do |custom_field|
          field = overview_page.open_inplace_edit_field_for_custom_field(custom_field)
          field.expect_field_label_with_help_text custom_field.name
          field.close
        end
      end

      it "shows help text modal on clicking help text link" do
        field = overview_page.open_inplace_edit_field_for_custom_field(multi_list_project_custom_field)

        field.click_help_text_link_for_label "Multi list field"

        expect(page).to have_modal "Multi list field"
        within_modal "Multi list field" do
          expect(page).to have_text "Attribute help text"

          click_on "Close"
        end
        expect(page).to have_no_modal "Multi list field"
      end
    end
  end
end
