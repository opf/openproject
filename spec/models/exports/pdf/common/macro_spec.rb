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

RSpec.describe Exports::PDF::Common::Macro do
  shared_let(:type_task) { create(:type_task) }
  shared_let(:custom_field) do
    create(
      :work_package_custom_field,
      name: "Custom Field 1",
      field_format: "string",
      types: [type_task]
    )
  end
  shared_let(:formatted_custom_field) do
    create(
      :work_package_custom_field,
      name: "Custom Formatted Field",
      field_format: "text",
      is_for_all: true,
      types: [type_task]
    )
  end
  shared_let(:project_custom_field_section) { create(:project_custom_field_section) }
  shared_let(:project_custom_field) do
    create(:string_project_custom_field, name: "Project Custom Field 1", project_custom_field_section:)
  end
  shared_let(:project) do
    create(
      :project,
      status_code: "on_track",
      work_package_custom_fields: [custom_field, formatted_custom_field],
      project_custom_fields: [project_custom_field],
      custom_field_values: { project_custom_field.id => "Project custom value 1" }
    )
  end
  shared_let(:other_project) do
    create(
      :project,
      name: "Other Project",
      work_package_custom_fields: [custom_field, formatted_custom_field],
      project_custom_fields: [project_custom_field],
      custom_field_values: { project_custom_field.id => "Project custom value 2" }
    )
  end
  shared_let(:other_work_package) do
    create(
      :work_package,
      subject: "Work package 2",
      project: other_project,
      type: type_task,
      custom_field_values: {
        custom_field.id => "Custom value 2"
      }
    )
  end
  shared_let(:restricted_other_project) do
    create(
      :project,
      name: "Other Project",
      work_package_custom_fields: [custom_field, formatted_custom_field],
      project_custom_fields: [project_custom_field],
      custom_field_values: { project_custom_field.id => "Project custom value 3" }
    )
  end
  shared_let(:restricted_work_package) do
    create(
      :work_package,
      subject: "Work package 3",
      project: restricted_other_project,
      type: type_task,
      custom_field_values: {
        custom_field.id => "Custom value 3"
      }
    )
  end
  shared_let(:formatter) { Class.new { extend Exports::PDF::Common::Macro } }
  let(:work_package) do
    create(
      :work_package,
      subject: "Work package 1",
      type: type_task,
      status: create(:status, name: "In Progress"),
      project: project,
      custom_field_values: {
        custom_field.id => "Custom value 1",
        formatted_custom_field.id => formatted_custom_field_value
      }
    )
  end
  let(:additional_permissions) { [] }
  let(:user) do
    create(
      :user,
      member_with_permissions: {
        project => %i[view_work_packages view_project_attributes view_project] + additional_permissions,
        other_project => %i[view_work_packages view_project_attributes view_project] + additional_permissions
      }
    )
  end
  let(:markdown) { "" }
  let(:formatted_custom_field_value) { "**Formatted** _text_ content" }

  before do
    User.current = user
  end

  subject(:formatted) do
    formatter
      .apply_markdown_field_macros(markdown, { work_package: work_package, project: project, user: })
      .chomp
  end

  describe "empty text" do
    it "contains correct data" do
      expect(formatted).to eq ""
    end
  end

  describe "wp mention macro" do
    let(:expected_tag) do
      "<mention class=\"mention\" data-id=\"#{
        work_package.id
      }\" data-type=\"work_package\" data-text=\"##{
        work_package.id
      }\">##{
        work_package.id
      }</mention>"
    end

    describe "with tag" do
      let(:markdown) { expected_tag }

      it "loops the tag through" do
        # note: escaped backslash in the tag text for correct markdown rendering
        expect(formatted).to eq("<mention class=\"mention\" data-id=\"#{
          work_package.id
        }\" data-type=\"work_package\" data-text=\"##{
          work_package.id
        }\">\\##{work_package.id}</mention>")
      end
    end

    describe "with plain" do
      let(:markdown) { "##{work_package.id}" }

      it "contains correct data" do
        expect(formatted).to eq(expected_tag)
      end
    end

    describe "with markdown formating bold" do
      let(:markdown) { "**##{work_package.id}**" }

      it "contains correct data" do
        expect(formatted).to eq("**#{expected_tag}**")
      end
    end

    describe "with markdown formating strikethrough" do
      let(:markdown) { "~~##{work_package.id}~~" }

      it "contains correct data" do
        expect(formatted).to eq("~~#{expected_tag}~~")
      end
    end

    describe "with strikethrough in table" do
      let(:markdown) { "<table><tr><td><p><s>##{work_package.id}</s></p></td></tr></table>" }

      it "contains correct data" do
        expect(formatted).to eq("<table><tr><td><p><s>#{expected_tag}</s></p></td></tr></table>")
      end
    end

    describe "with semantic identifier" do
      describe "in semantic mode",
               with_settings: { work_packages_identifier: "semantic" } do
        let(:semantic_project) { create(:project, identifier: "PROJ") }
        let(:semantic_work_package) do
          wp = create(:work_package, project: semantic_project, type: type_task, subject: "Semantic")
          wp.allocate_and_register_semantic_id
          wp.reload
        end
        let(:user) do
          create(
            :user,
            member_with_permissions: {
              project => %i[view_work_packages view_project_attributes view_project] + additional_permissions,
              other_project => %i[view_work_packages view_project_attributes view_project] + additional_permissions,
              semantic_project => %i[view_work_packages view_project_attributes view_project]
            }
          )
        end

        describe "alone" do
          let(:markdown) { "see ##{semantic_work_package.identifier} here" }

          it "renders the mention with the semantic identifier in data-id" do
            expect(formatted).to include(%(data-id="#{semantic_work_package.identifier}"))
            expect(formatted).to include(%(data-text="##{semantic_work_package.identifier}"))
          end
        end

        describe "mixed with a numeric reference" do
          let(:markdown) { "see ##{semantic_work_package.identifier} and ##{work_package.id}" }

          it "renders both as mentions with their respective data-ids" do
            expect(formatted).to include(%(data-id="#{semantic_work_package.identifier}"))
            expect(formatted).to include(%(data-id="#{work_package.id}"))
            expect(formatted).not_to include('data-id="0"')
          end
        end

        describe "with an alias from a previous identifier" do
          before do
            create(:work_package_semantic_alias,
                   work_package: semantic_work_package,
                   identifier: "OLD-1")
          end

          let(:markdown) { "see #OLD-1 here" }

          it "resolves the alias and renders the current identifier" do
            expect(formatted).to include(%(data-id="#{semantic_work_package.identifier}"))
            expect(formatted).to include(%(data-text="##{semantic_work_package.identifier}"))
            expect(formatted).not_to include(">#OLD-1<")
          end
        end

        describe "for a missing work package" do
          let(:markdown) { "see #GHOST-99 here" }

          it "falls through to literal text without crashing" do
            expect(formatted).to include("#GHOST-99")
            expect(formatted).not_to include("<mention")
            expect(formatted).not_to include('data-id="0"')
          end
        end

        describe "for a work package the user cannot see" do
          let(:hidden_project) { create(:project, identifier: "HIDDEN") }
          let(:hidden_work_package) do
            wp = create(:work_package, project: hidden_project, type: type_task, subject: "Hidden")
            wp.allocate_and_register_semantic_id
            wp.reload
          end
          let(:markdown) { "see ##{hidden_work_package.identifier} here" }

          it "falls through to literal text and does not disclose the work package" do
            expect(formatted).to include("##{hidden_work_package.identifier}")
            expect(formatted).not_to include("<mention")
          end
        end
      end

      describe "in classic mode",
               with_settings: { work_packages_identifier: "classic" } do
        let(:markdown) { "see #PROJ-1 here" }

        it "falls through to literal text without emitting a mention" do
          expect(formatted).to include("#PROJ-1")
          expect(formatted).not_to include("<mention")
          expect(formatted).not_to include('data-id="0"')
        end
      end
    end
  end

  describe "workPackageValue macro" do
    describe "with current work package attribute" do
      let(:markdown) { "workPackageValue:subject" }

      it "outputs the attribute value" do
        expect(formatted).to eq("Work package 1")
      end
    end

    describe "with specific work package ID and attribute" do
      let(:markdown) { "workPackageValue:#{work_package.id}:subject" }

      it "outputs the attribute value for the specified work package" do
        expect(formatted).to eq("Work package 1")
      end
    end

    describe "withh another work package ID and attribute" do
      let(:markdown) { "workPackageValue:#{other_work_package.id}:subject" }

      it "outputs the attribute value for the specified work package" do
        expect(formatted).to eq("Work package 2")
      end
    end

    describe "with a semantic work package identifier",
             with_settings: { work_packages_identifier: "semantic" } do
      let(:semantic_project) { create(:project, identifier: "PROJ") }
      let(:semantic_work_package) do
        wp = create(:work_package, project: semantic_project, type: type_task, subject: "Semantic subject")
        wp.allocate_and_register_semantic_id
        wp.reload
      end
      let(:user) do
        create(
          :user,
          member_with_permissions: {
            project => %i[view_work_packages view_project_attributes view_project],
            semantic_project => %i[view_work_packages view_project_attributes view_project]
          }
        )
      end
      let(:markdown) { "workPackageValue:#{semantic_work_package.identifier}:subject" }

      it "outputs the attribute value for the work package addressed by its semantic identifier" do
        expect(formatted).to eq("Semantic subject")
      end
    end

    describe "with restricted work package ID and attribute" do
      let(:markdown) { "workPackageValue:#{restricted_work_package.id}:subject" }

      it "outputs an error message" do
        expect(formatted).to include("Macro error, resource not found")
      end
    end

    describe "with restricted work package ID and custom field" do
      let(:markdown) { "workPackageValue:#{restricted_work_package.id}:\"Custom Field 1\"" }

      it "outputs an error message" do
        expect(formatted).to include("Macro error, resource not found")
      end
    end

    describe "with restricted work package ID and formatted custom field" do
      let(:markdown) { "workPackageValue:#{restricted_work_package.id}:\"Custom Formatted Field\"" }

      it "outputs an error message" do
        expect(formatted).to include("Macro error, resource not found")
      end
    end

    describe "with non-existent work package ID" do
      let(:markdown) { "workPackageValue:999:subject" }

      it "outputs an error message" do
        expect(formatted).to include("Macro error, resource not found")
      end
    end

    describe "with status attribute" do
      let(:markdown) { "workPackageValue:status" }

      it "outputs the status name" do
        expect(formatted).to eq("In Progress")
      end
    end

    describe "with project_phase attribute" do
      let(:project_phase_active) { true }
      let!(:project_phase) do
        create(:project_phase, project: project, active: project_phase_active)
      end
      let(:markdown) { "workPackageValue:project_phase" }

      before do
        work_package.update!(project_phase_definition_id: project_phase.definition.id)
      end

      describe "without the permission" do
        it "outputs a single space" do
          expect(formatted).to eq(" ")
        end
      end

      describe "with the permission" do
        let(:additional_permissions) { [:view_project_phases] }

        describe "with active phase" do
          it "outputs the project phase name" do
            expect(formatted).to eq(project_phase.name)
          end
        end

        describe "without active phase" do
          let(:project_phase_active) { false }

          it "outputs the project phase name" do
            expect(formatted).to eq(" ")
          end
        end
      end
    end

    describe "with custom field by name" do
      let(:markdown) { 'workPackageValue:"Custom Field 1"' }

      it "outputs the custom field value" do
        expect(formatted).to eq("Custom value 1")
      end
    end

    describe "with specific work package ID and custom field" do
      let(:markdown) { "workPackageValue:#{work_package.id}:\"Custom Field 1\"" }

      it "outputs the custom field value for the specified work package" do
        expect(formatted).to eq("Custom value 1")
      end
    end

    describe "with another work package ID and custom field" do
      let(:markdown) { "workPackageValue:#{other_work_package.id}:\"Custom Field 1\"" }

      it "outputs the custom field value for the specified work package" do
        expect(formatted).to eq("Custom value 2")
      end
    end

    describe "with nested formatted custom field" do
      let(:formatted_custom_field_value) { "a complicated **formatted** _text_ with <table></table>" }

      describe "with relative work package" do
        let(:markdown) { '<table><tr><td>workPackageValue:"Custom Formatted Field"</td></tr></table>' }

        it "outputs an error message for rich text" do
          expect(formatted).to include(I18n.t("export.macro.nested_rich_text_unsupported"))
        end
      end

      describe "with specific work package ID" do
        let(:markdown) { "<table><tr><td>workPackageValue:#{work_package.id}:\"Custom Formatted Field\"</td></tr></table>" }

        it "outputs an error message for rich text" do
          expect(formatted).to include(I18n.t("export.macro.nested_rich_text_unsupported"))
        end
      end
    end

    describe "with formatted custom field" do
      describe "with relative work package" do
        let(:markdown) { 'workPackageValue:"Custom Formatted Field"' }

        it "outputs an error message for rich text" do
          expect(formatted).to eq("**Formatted** _text_ content")
        end
      end

      describe "with specific work package ID" do
        let(:markdown) { "workPackageValue:#{work_package.id}:\"Custom Formatted Field\"" }

        it "outputs an error message for rich text" do
          expect(formatted).to eq("**Formatted** _text_ content")
        end
      end
    end

    describe "with non-existent attribute" do
      let(:markdown) { "workPackageValue:nonexistent_attribute" }

      it "outputs an empty value" do
        expect(formatted).to eq(" ")
      end
    end

    describe "with another work package id and a non-existent attribute" do
      let(:markdown) { "workPackageValue:#{other_work_package.id}:nonexistent_attribute" }

      it "outputs an empty value" do
        expect(formatted).to eq(" ")
      end
    end

    describe "with two macros in a single line" do
      let(:markdown) { 'workPackageValue:"Custom Field 1" workPackageValue:subject' }

      it "renders both macro values" do
        expect(formatted).to eq("Custom value 1 Work package 1")
      end
    end

    describe "with markdown formatting" do
      let(:markdown) { "**workPackageValue:subject**" }

      it "preserves the markdown formatting" do
        expect(formatted).to eq("**Work package 1**")
      end
    end

    describe "in a table" do
      let(:markdown) { "<table><tr><td>workPackageValue:subject</td></tr></table>" }

      it "processes the macro inside HTML" do
        expect(formatted).to eq("<table><tr><td>Work package 1</td></tr></table>")
      end
    end

    describe "with formatted custom field used mid-line and markdown structures" do
      # Ensure that when a formatted custom field contains markdown that MUST start at BOL
      # and the macro appears mid-line, a line break is inserted before the markdown.
      context "with unordered list item" do
        let(:markdown) { "\nPrefix workPackageValue:\"Custom Formatted Field\"" }
        let(:formatted_custom_field_value) { "* list item" }

        it "inserts a newline before the list to keep structure" do
          expect(formatted).to eq("Prefix \n* list item")
        end
      end

      context "with blockquote" do
        let(:markdown) { "\nIntro workPackageValue:\"Custom Formatted Field\"" }
        let(:formatted_custom_field_value) { "> quoted" }

        it "inserts a newline before the blockquote to keep structure" do
          expect(formatted).to eq("Intro \n> quoted")
        end
      end

      context "with heading" do
        let(:markdown) { "\nText workPackageValue:\"Custom Formatted Field\"" }
        let(:formatted_custom_field_value) { "# Heading" }

        it "inserts a newline before the header to keep structure" do
          expect(formatted).to eq("Text \n# Heading")
        end
      end

      context "with fenced code block" do
        let(:markdown) { "\nPreamble workPackageValue:\"Custom Formatted Field\"" }
        let(:formatted_custom_field_value) { "```\ncode\n```" }

        it "inserts a newline before the fenced code block to keep structure" do
          expect(formatted).to eq("Preamble \n```\ncode\n```")
        end
      end
    end
  end

  describe "workPackageLabel macro" do
    let!(:original_setting) { ActiveModel::Translation.raise_on_missing_translations }

    before do
      ActiveModel::Translation.raise_on_missing_translations = false
    end

    after do
      ActiveModel::Translation.raise_on_missing_translations = original_setting
    end

    describe "with current work package attribute" do
      let(:markdown) { "workPackageLabel:subject" }

      it "outputs the attribute label" do
        expect(formatted).to eq("Subject")
      end
    end

    describe "with specific work package ID and attribute" do
      let(:markdown) { "workPackageLabel:#{work_package.id}:subject" }

      it "outputs the attribute label for the specified work package" do
        expect(formatted).to eq("Subject")
      end
    end

    describe "with non-existent work package ID" do
      let(:markdown) { "workPackageLabel:999:subject" }

      it "outputs a humanized form" do
        expect(formatted).to eq("Subject")
      end
    end

    describe "with status attribute" do
      let(:markdown) { "workPackageLabel:status" }

      it "outputs the status label" do
        expect(formatted).to eq("Status")
      end
    end

    describe "with custom field by name" do
      let(:markdown) { 'workPackageLabel:"Custom Field 1"' }

      it "outputs the custom field name" do
        expect(formatted).to eq("Custom field 1")
      end
    end

    describe "with specific work package ID and custom field" do
      let(:markdown) { "workPackageLabel:#{work_package.id}:\"Custom Field 1\"" }

      it "outputs the custom field name for the specified work package" do
        expect(formatted).to eq("Custom field 1")
      end
    end

    describe "with non-existent attribute" do
      let(:markdown) { "workPackageLabel:nonexistent_attribute" }

      it "outputs the humanized attribute name" do
        expect(formatted).to eq("Nonexistent attribute")
      end
    end

    describe "with markdown formatting" do
      let(:markdown) { "**workPackageLabel:subject**" }

      it "preserves the markdown formatting" do
        expect(formatted).to eq("**Subject**")
      end
    end

    describe "in a table" do
      let(:markdown) { "<table><tr><td>workPackageLabel:subject</td></tr></table>" }

      it "processes the macro inside HTML" do
        expect(formatted).to eq("<table><tr><td>Subject</td></tr></table>")
      end
    end
  end

  describe "projectValue macro" do
    describe "with current project attribute" do
      let(:markdown) { "projectValue:name" }

      it "outputs the attribute value" do
        expect(formatted).to eq(project.name)
      end
    end

    describe "with specific project ID and attribute" do
      let(:markdown) { "projectValue:#{project.id}:name" }

      it "outputs the attribute value for the specified project" do
        expect(formatted).to eq(project.name)
      end
    end

    describe "with other project ID and attribute" do
      let(:markdown) { "projectValue:#{other_project.id}:name" }

      it "outputs the attribute value for the specified project" do
        expect(formatted).to eq(other_project.name)
      end
    end

    describe "with specific project identifier and attribute" do
      let(:markdown) { "projectValue:\"#{project.identifier}\":name" }

      it "outputs the attribute value for the specified project" do
        expect(formatted).to eq(project.name)
      end
    end

    describe "with other project identifier and attribute" do
      let(:markdown) { "projectValue:\"#{other_project.identifier}\":name" }

      it "outputs the attribute value for the specified project" do
        expect(formatted).to eq(other_project.name)
      end
    end

    describe "with non-existent project ID" do
      let(:markdown) { "projectValue:999:name" }

      it "outputs an error message" do
        expect(formatted).to include("Macro error, resource not found")
      end
    end

    describe "with restricted project ID" do
      let(:markdown) { "projectValue:#{restricted_other_project.id}:name" }

      it "outputs an error message" do
        expect(formatted).to include("Macro error, resource not found")
      end
    end

    describe "with restricted project identifier" do
      let(:markdown) { "projectValue:\"#{restricted_other_project.identifier}\":name" }

      it "outputs an error message" do
        expect(formatted).to include("Macro error, resource not found")
      end
    end

    describe "with restricted project ID and custom field" do
      let(:markdown) { "projectValue:#{restricted_other_project.id}:\"Project Custom Field 1\"" }

      it "outputs an error message" do
        expect(formatted).to include("Macro error, resource not found")
      end
    end

    describe "with status attribute" do
      let(:markdown) { "projectValue:status_code" }

      it "outputs the status code" do
        expect(formatted).to eq(project.status_code)
      end
    end

    describe "with custom field by name" do
      let(:markdown) { 'projectValue:"Project Custom Field 1"' }

      it "outputs the custom field value" do
        expect(formatted).to eq("Project custom value 1")
      end
    end

    describe "with specific project ID and custom field" do
      let(:markdown) { "projectValue:#{project.id}:\"Project Custom Field 1\"" }

      it "outputs the custom field value for the specified project" do
        expect(formatted).to eq("Project custom value 1")
      end
    end

    describe "with other project ID and custom field" do
      let(:markdown) { "projectValue:#{other_project.id}:\"Project Custom Field 1\"" }

      it "outputs the custom field value for the specified project" do
        expect(formatted).to eq("Project custom value 2")
      end
    end

    describe "with non-existent attribute" do
      let(:markdown) { "projectValue:nonexistent_attribute" }

      it "outputs an empty value" do
        expect(formatted).to eq(" ")
      end
    end

    describe "with markdown formatting" do
      let(:markdown) { "**projectValue:name**" }

      it "preserves the markdown formatting" do
        expect(formatted).to eq("**#{project.name}**")
      end
    end

    describe "in a table" do
      let(:markdown) { "<table><tr><td>projectValue:name</td></tr></table>" }

      it "processes the macro inside HTML" do
        expect(formatted).to eq("<table><tr><td>#{project.name}</td></tr></table>")
      end
    end
  end

  describe "projectLabel macro" do
    let!(:original_setting) { ActiveModel::Translation.raise_on_missing_translations }

    before do
      ActiveModel::Translation.raise_on_missing_translations = false
    end

    after do
      ActiveModel::Translation.raise_on_missing_translations = original_setting
    end

    describe "with current project attribute" do
      let(:markdown) { "projectLabel:name" }

      it "outputs the attribute label" do
        expect(formatted).to eq("Name")
      end
    end

    describe "with specific project ID and attribute" do
      let(:markdown) { "projectLabel:#{project.id}:name" }

      it "outputs the attribute label for the specified project" do
        expect(formatted).to eq("Name")
      end
    end

    describe "with specific project identifier and attribute" do
      let(:markdown) { "projectLabel:\"#{project.identifier}\":name" }

      it "outputs the attribute label for the specified project" do
        expect(formatted).to eq("Name")
      end
    end

    describe "with non-existent project ID" do
      let(:markdown) { "projectLabel:999:name" }

      it "outputs the attribute label" do
        expect(formatted).to eq("Name")
      end
    end

    describe "with status attribute" do
      let(:markdown) { "projectLabel:status_code" }

      it "outputs the status label" do
        expect(formatted).to eq("Status")
      end
    end

    describe "with custom field by name" do
      let(:markdown) { 'projectLabel:"Project Custom Field 1"' }

      it "outputs the custom field name" do
        expect(formatted).to eq("Project custom field 1")
      end
    end

    describe "with specific project ID and custom field" do
      let(:markdown) { "projectLabel:#{project.id}:\"Project Custom Field 1\"" }

      it "outputs the custom field name for the specified project" do
        expect(formatted).to eq("Project custom field 1")
      end
    end

    describe "with non-existent attribute" do
      let(:markdown) { "projectLabel:nonexistent_attribute" }

      it "outputs the humanized attribute name" do
        expect(formatted).to eq("Nonexistent attribute")
      end
    end

    describe "with markdown formatting" do
      let(:markdown) { "**projectLabel:name**" }

      it "preserves the markdown formatting" do
        expect(formatted).to eq("**Name**")
      end
    end

    describe "in a table" do
      let(:markdown) { "<table><tr><td>projectLabel:name</td></tr></table>" }

      it "processes the macro inside HTML" do
        expect(formatted).to eq("<table><tr><td>Name</td></tr></table>")
      end
    end
  end
end
