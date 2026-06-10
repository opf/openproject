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
#
require "spec_helper"

RSpec.describe Primer::OpenProject::Forms::Dsl::InputMethods, type: :forms do
  let(:form_object) { Primer::Forms::Dsl::FormObject.extend(described_class) }
  let(:builder) { instance_double(ActionView::Helpers::FormBuilder, object: model) }
  let(:form) { instance_double(ApplicationForm, model:, caption_template?: false) }
  let(:form_dsl) { form_object.new(builder:, form:) }

  let(:name) { :subject }
  let(:label) { "Subject" }
  let(:options) { {} }

  let(:model) { build_stubbed(:project) }

  subject(:field) { field_group.first }

  before do
    allow(form).to receive(:wrap_attribute_label_with_help_text) do |label, name|
      "#{label} <fake-attribute-help-text for='#{name}'/>"
    end
  end

  shared_examples_for "input class" do |input_class|
    it "instantiates correct input class" do
      expect(field).to be_a(input_class)
    end
  end

  shared_examples_for "supporting help texts" do
    context "when include_help_text: option is true (default)" do
      context "when no additional help_text_options: are passed" do
        it "wraps the label with help text" do
          expect(field.label).to start_with(label)
            .and end_with("<fake-attribute-help-text for='#{name}'/>")
        end
      end

      context "when additional help_text_options: are passed" do
        let(:attribute_name) { :subject_attribute }
        let(:options) { { help_text_options: { attribute_name: } } }

        it "wraps the label with help text" do
          expect(field.label).to start_with(label)
            .and end_with("<fake-attribute-help-text for='#{attribute_name}'/>")
        end
      end
    end

    context "when include_help_text: option is false" do
      let(:options) { { include_help_text: false } }

      it "does not wrap the label" do
        expect(field.label).to eq label
      end
    end
  end

  describe "multi input methods" do
    describe "#multi" do
      let(:field_group) { form_dsl.multi(name:, label:, **options) }

      include_examples "input class", Primer::Forms::Dsl::MultiInput
      it_behaves_like "supporting help texts"
    end

    describe "#check_box" do
      let(:field_group) { form_dsl.check_box(name:, label:, **options) }

      include_examples "input class", Primer::Forms::Dsl::CheckBoxInput
      it_behaves_like "supporting help texts"
    end

    describe "#radio_button_group" do
      let(:field_group) { form_dsl.radio_button_group(name:, label:, **options) }

      include_examples "input class", Primer::Forms::Dsl::RadioButtonGroupInput
      it_behaves_like "supporting help texts"
    end

    describe "#check_box_group" do
      let(:field_group) { form_dsl.check_box_group(name:, label:, **options) }

      include_examples "input class", Primer::Forms::Dsl::CheckBoxGroupInput
      it_behaves_like "supporting help texts"
    end

    describe "#advanced_radio_button_group" do
      let(:field_group) { form_dsl.advanced_radio_button_group(name:, label:, **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::AdvancedRadioButtonGroupInput
      it_behaves_like "supporting help texts"
    end

    describe "#advanced_check_box_group" do
      let(:field_group) { form_dsl.advanced_check_box_group(name:, label:, **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::AdvancedCheckBoxGroupInput
      it_behaves_like "supporting help texts"
    end
  end

  describe "#separator" do
    let(:field_group) { form_dsl.separator }

    include_examples "input class", Primer::Forms::Separator
  end

  describe "#html_content" do
    let(:field_group) { form_dsl.html_content { "content" } }

    include_examples "input class", Primer::OpenProject::Forms::HtmlContent
  end

  describe "text input methods" do
    describe "#text_field" do
      let(:field_group) { form_dsl.text_field(name:, label:, **options) }

      include_examples "input class", Primer::Forms::Dsl::TextFieldInput
      it_behaves_like "supporting help texts"
    end

    describe "#auto_complete" do
      let(:field_group) { form_dsl.auto_complete(name:, label:, **options) }

      include_examples "input class", Primer::Forms::Dsl::AutoCompleteInput
      it_behaves_like "supporting help texts"
    end

    describe "#text_area" do
      let(:field_group) { form_dsl.text_area(name:, label:, **options) }

      include_examples "input class", Primer::Forms::Dsl::TextAreaInput
      it_behaves_like "supporting help texts"
    end
  end

  describe "select input methods" do
    describe "#select_list" do
      let(:field_group) { form_dsl.select_list(name:, label:, **options) }

      include_examples "input class", Primer::Forms::Dsl::SelectInput
      it_behaves_like "supporting help texts"
    end

    describe "#action_menu" do
      let(:field_group) { form_dsl.action_menu(name:, label:, **options) }

      include_examples "input class", Primer::Forms::Dsl::ActionMenuInput
      it_behaves_like "supporting help texts"
    end
  end

  describe "button input methods" do
    describe "#submit" do
      let(:field_group) { form_dsl.submit(name:, label:, **options) }

      include_examples "input class", Primer::Forms::Dsl::SubmitButtonInput
      it_behaves_like "supporting help texts"
    end

    describe "#button" do
      let(:field_group) { form_dsl.button(name:, label:, **options) }

      include_examples "input class", Primer::Forms::Dsl::ButtonInput
      it_behaves_like "supporting help texts"
    end
  end

  describe "OpenProject input methods" do
    describe "#autocompleter" do
      let(:field_group) { form_dsl.autocompleter(name:, label:, autocomplete_options: {}, **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::AutocompleterInput
      it_behaves_like "supporting help texts"
    end

    describe "#pattern_input" do
      let(:field_group) { form_dsl.pattern_input(name:, label:, value: "", suggestions: [], **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::PatternInput
      it_behaves_like "supporting help texts"
    end

    describe "#color_select_list" do
      let(:field_group) { form_dsl.color_select_list(name:, label:, **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::ColorSelectInput
      it_behaves_like "supporting help texts"
    end

    describe "#project_autocompleter" do
      let(:field_group) { form_dsl.project_autocompleter(name:, label:, autocomplete_options: {}, **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::ProjectAutocompleterInput
      it_behaves_like "supporting help texts"
    end

    describe "#single_date_picker" do
      let(:field_group) { form_dsl.single_date_picker(name:, label:, **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::SingleDatePickerInput
      it_behaves_like "supporting help texts"
    end

    describe "#range_date_picker" do
      let(:field_group) { form_dsl.range_date_picker(name:, label:, **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::RangeDatePickerInput
      it_behaves_like "supporting help texts"
    end

    describe "#rich_text_area" do
      let(:field_group) { form_dsl.rich_text_area(name:, label:, rich_text_options: {}, **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::RichTextAreaInput
      it_behaves_like "supporting help texts"
    end

    describe "#block_note_editor" do
      let(:document_name) { "1234asdzxc" }
      let(:field_group) do
        form_dsl.block_note_editor(name:, label:, value: "", document_id: 8, document_name:, attachments_upload_url: "",
                                   attachments_collection_key: "", **options)
      end

      include_examples "input class", Primer::OpenProject::Forms::Dsl::BlockNoteEditorInput
      it_behaves_like "supporting help texts"
    end

    describe "#storage_manual_project_folder_selection" do
      let(:project_storage) { build_stubbed(:project_storage) }
      let(:field_group) { form_dsl.storage_manual_project_folder_selection(name:, label:, project_storage:, **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::StorageManualProjectFolderSelectionInput
      it_behaves_like "supporting help texts"
    end

    describe "#work_package_autocompleter" do
      let(:field_group) { form_dsl.work_package_autocompleter(name:, label:, autocomplete_options: {}, **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::WorkPackageAutocompleterInput
      it_behaves_like "supporting help texts"
    end

    describe "#select_panel" do
      let(:field_group) { form_dsl.select_panel(name:, label:, **options) }

      include_examples "input class", Primer::OpenProject::Forms::Dsl::SelectPanelInput
      it_behaves_like "supporting help texts"
    end

    describe "#segmented_control" do
      let(:field_group) do
        form_dsl.segmented_control(name:, label:, value: "a", items: [{ value: "a", label: "A" }], **options)
      end

      include_examples "input class", Primer::OpenProject::Forms::Dsl::SegmentedControlInput
      it_behaves_like "supporting help texts"
    end
  end
end
