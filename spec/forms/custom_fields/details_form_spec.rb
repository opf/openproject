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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

format_cases = {
  WorkPackageCustomField => %w[hierarchy],
  TimeEntryCustomField => %w[text date float user version string bool list int],
  VersionCustomField => %w[text date float int user bool string list version],
  GroupCustomField => %w[text date float int bool list string],
  ProjectCustomField => %w[
    text date link calculated_value float weighted_item_list user bool hierarchy int string list version
  ],
  UserCustomField => %w[text date float int hierarchy list string bool]
}.freeze

RSpec.describe CustomFields::DetailsForm, type: :forms do
  include_context "with rendered form"

  let(:field_rules) do
    {
      custom_field_section_id: ->(model) { model.is_a?(ProjectCustomField) || model.is_a?(UserCustomField) },
      has_comment: ->(model) { model.is_a?(ProjectCustomField) },
      is_filter: ->(model) { model.is_a?(WorkPackageCustomField) },
      content_right_to_left: ->(model) { model.is_a?(WorkPackageCustomField) && model.field_format == "text" },
      editable: ->(model) { model.is_a?(UserCustomField) },
      visible_on_user_card: ->(model) { model.is_a?(UserCustomField) },
      is_for_all: ->(model) { model.is_a?(WorkPackageCustomField) || model.is_a?(ProjectCustomField) },
      searchable: lambda { |model|
        (model.is_a?(WorkPackageCustomField) || model.is_a?(ProjectCustomField)) &&
          %w[string text link list].include?(model.field_format)
      },
      admin_only: ->(model) { model.is_a?(ProjectCustomField) || model.is_a?(UserCustomField) },
      min_length: ->(model) { %w[string int float text].include?(model.field_format) },
      max_length: ->(model) { %w[string int float text].include?(model.field_format) },
      regexp: ->(model) { %w[string int float text link].include?(model.field_format) },
      default_value: ->(model) { %w[string int float text link bool].include?(model.field_format) },
      multi_value: ->(model) { %w[list user version hierarchy].include?(model.field_format) },
      is_required: ->(model) { %w[calculated_value bool].exclude?(model.field_format) },
      formula: ->(model) { model.field_format == "calculated_value" },
      allow_non_open_versions: ->(model) { model.field_format == "version" }
    }
  end

  let(:form_arguments) { { url: "/foo", model:, scope: :custom_field } }
  let(:model) { model_class.new(field_format:, formula: "2 + 2") }

  prepend_before do
    create(:project_custom_field_section) if model_class == ProjectCustomField
    create(:user_custom_field_section) if model_class == UserCustomField
  end

  def field_label(field)
    case field
    when :custom_field_section_id
      I18n.t("activerecord.attributes.project_custom_field.custom_field_section")
    when :formula
      I18n.t(:label_formula)
    else
      I18n.t("activerecord.attributes.custom_field.#{field}")
    end
  end

  def expect_labeled_control(field)
    label = field_label(field)
    name = "custom_field[#{field}]"

    if field == :formula
      expect(page).to have_selector(:pattern_input, label)
      expect(page).to have_css("input[type='hidden'][name='#{name}']", visible: :all)
    elsif field == :default_value && field_format == "text"
      expect(page).to have_selector(:rich_text_field, label)
      expect(page).to have_field(label, type: "textarea", name:, visible: :all)
    else
      expect(page).to have_field(label, type: control_type(field), name:)
    end
  end

  def control_type(field)
    case field
    when :custom_field_section_id then "select"
    when :min_length, :max_length then "number"
    when :regexp then "text"
    when :default_value then field_format == "bool" ? "checkbox" : "text"
    else "checkbox"
    end
  end

  format_cases.each do |custom_field_class, formats|
    formats.each do |format|
      context "with a #{custom_field_class.name} in #{format} format" do
        let(:model_class) { custom_field_class }
        let(:field_format) { format }

        it "renders labeled controls of the correct type for the format", :aggregate_failures do
          expect(page).to have_field(I18n.t(:label_name), type: "text", name: "custom_field[name]")
          field_rules.each do |field, visible|
            selector = "[name='custom_field[#{field}]']"

            if visible.call(model)
              expect_labeled_control(field)
            else
              expect(page).to have_no_css(selector, visible: :all)
              expect(page).to have_no_selector(:label, field_label(field))
            end
          end
        end
      end
    end
  end
end
