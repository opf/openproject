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

require "rails_helper"

RSpec.describe Admin::CustomFields::Projects::ValueDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, name: "Scrum project") }

  let(:value) { nil }
  let(:parent) { nil }
  let(:parent_options) { rendered.css("select[name='parent_id'] option").map { it.text.strip } }
  let(:field_names) { rendered.css("input:not([type='hidden']), select").pluck("name") }

  subject(:rendered) { render_inline(described_class.new(custom_field:, project:, value:, parent:)) }

  context "for a list custom field" do
    let(:custom_field) { create(:list_wp_custom_field, allow_additional_project_values: true) }

    it "asks for the name of the value in the project" do
      expect(rendered).to have_text(I18n.t("custom_fields.admin.projects.value_dialog.title"))
      expect(rendered).to have_field(I18n.t("custom_fields.admin.projects.value_dialog.name"))
      expect(rendered).to have_text(
        I18n.t("custom_fields.admin.projects.value_dialog.name_caption", project: "Scrum project")
      )
      expect(rendered.css("form").attr("action").value)
        .to eq(admin_settings_work_package_custom_field_project_specific_values_path(custom_field, project))
      expect(rendered).to have_button(I18n.t(:button_add))
    end

    it "does not ask for a parent, short name or weight" do
      expect(rendered).to have_no_field(I18n.t("custom_fields.admin.projects.value_dialog.parent"))
      expect(rendered).to have_no_field(I18n.t("custom_fields.admin.items.placeholder.short"))
      expect(rendered).to have_no_field(I18n.t("custom_fields.admin.items.placeholder.weight"))
    end

    context "when editing a value of the project" do
      let(:value) { custom_field.custom_options.create!(value: "Own", project:) }

      it "updates the value" do
        expect(rendered).to have_text(I18n.t("custom_fields.admin.projects.value_dialog.edit_title"))
        expect(rendered).to have_field(I18n.t("custom_fields.admin.projects.value_dialog.name"), with: "Own")
        expect(rendered.css("form").attr("action").value)
          .to eq(admin_settings_work_package_custom_field_project_specific_value_path(custom_field, project, value.id))
        expect(rendered.css("input[name='_method']").attr("value").value).to eq("patch")
        expect(rendered).to have_button(I18n.t(:button_save))
      end
    end
  end

  context "for a hierarchy custom field", with_ee: %i[custom_field_hierarchies] do
    let(:custom_field) { create(:hierarchy_wp_custom_field, allow_additional_project_values: true) }
    let!(:global_item) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Global") }
    let!(:own_item) { create(:hierarchy_item, parent: global_item, label: "Own", project:) }
    let!(:foreign_item) { create(:hierarchy_item, parent: global_item, label: "Foreign", project: create(:project)) }

    it "offers the top level and the indented values of the project as parents" do
      expect(parent_options)
        .to eq([I18n.t("custom_fields.admin.projects.value_dialog.top_level"), "Global", "  Own"])
    end

    it "asks for a short name before the parent" do
      expect(field_names).to eq(%w[label short parent_id])
    end

    context "when adding a sub-value" do
      let(:parent) { global_item }

      it "preselects the parent" do
        expect(rendered).to have_text(
          I18n.t("custom_fields.admin.projects.value_dialog.title_with_parent", parent: "Global")
        )
        expect(rendered).to have_select(I18n.t("custom_fields.admin.projects.value_dialog.parent"),
                                        selected: "Global")
      end
    end

    context "when editing a value of the project" do
      let(:value) { own_item }

      before do
        own_item.update!(short: "OW")
      end

      it "shows the name and short name without the parent" do
        expect(field_names).to eq(%w[label short])
        expect(rendered).to have_field(I18n.t("custom_fields.admin.projects.value_dialog.name"), with: "Own")
        expect(rendered).to have_field(I18n.t("custom_fields.admin.items.placeholder.short"), with: "OW")
      end
    end
  end

  context "for a weighted list custom field", with_ee: %i[weighted_item_lists] do
    let(:custom_field) { create(:weighted_item_list_wp_custom_field, allow_additional_project_values: true) }

    it "asks for a weight before the parent" do
      expect(field_names).to eq(%w[label weight parent_id])
      expect(rendered).to have_field(I18n.t("custom_fields.admin.items.placeholder.weight"), type: "number")
    end
  end
end
