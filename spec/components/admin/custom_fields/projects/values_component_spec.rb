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

RSpec.describe Admin::CustomFields::Projects::ValuesComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project) }

  subject(:rendered) { render_inline(described_class.new(custom_field:, project:)) }

  let(:row) { ->(value) { rendered.css("[data-test-selector='custom-field-project-value-#{value.id}']") } }

  context "for a list custom field", with_ee: %i[project_specific_list_values] do
    let(:custom_field) { create(:list_wp_custom_field, :project_specific_allowlist, possible_values: %w[A B]) }
    let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
    let(:option_b) { custom_field.custom_options.find_by!(value: "B") }

    before do
      create(:project_specific_value_restriction, project:, custom_option: option_a)
    end

    it "offers to enable and to disable all values" do
      expect(rendered).to have_link(
        I18n.t("custom_fields.admin.projects.enable_all"),
        href: enable_all_project_values_admin_settings_work_package_custom_field_path(custom_field, project)
      )
      expect(rendered).to have_link(
        I18n.t("custom_fields.admin.projects.disable_all"),
        href: disable_all_project_values_admin_settings_work_package_custom_field_path(custom_field, project)
      )
    end

    it "toggles each value on its own" do
      expect(row.call(option_a).css("toggle-switch").attr("src").value)
        .to eq(toggle_project_value_admin_settings_work_package_custom_field_path(custom_field, project, option_a.id))
    end

    it "lists the options in order with whether they are enabled in the project" do
      expect(rendered.css("[data-test-selector^='custom-field-project-value-']").map { it.text.split.first })
        .to eq(%w[A B])
      expect(row.call(option_a).css("button[aria-pressed='true']")).to be_present
      expect(row.call(option_b).css("button[aria-pressed='false']")).to be_present
    end
  end

  context "when the enterprise plan does not include project-specific values" do
    let(:custom_field) { create(:list_wp_custom_field, :project_specific_allowlist, possible_values: %w[A]) }
    let(:option) { custom_field.custom_options.first }

    it "shows the values without allowing to change them" do
      expect(rendered).to have_text(I18n.t("ee.upsell.project_specific_list_values.description"))
      expect(rendered).to have_no_link(I18n.t("custom_fields.admin.projects.enable_all"))
      expect(rendered).to have_no_link(I18n.t("custom_fields.admin.projects.disable_all"))
      expect(row.call(option).css("toggle-switch button[disabled]")).to be_present
    end
  end

  context "for a weighted item list custom field", with_ee: %i[weighted_item_lists project_specific_list_values] do
    let(:custom_field) { create(:weighted_item_list_wp_custom_field, :project_specific_allowlist) }
    let!(:parent) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "High", weight: 10) }
    let!(:child) { create(:hierarchy_item, parent:, label: "Urgent", weight: 15) }

    it "indents sub-items and shows their weight and number of sub-items" do
      expect(row.call(parent).text).to include("High", "10", I18n.t("custom_fields.admin.hierarchy.subitems", count: 1))
      expect(row.call(child).text).to include("Urgent", "15")
      expect(row.call(child).css(".pl-3")).to be_present
      expect(row.call(parent).css(".pl-3")).to be_empty
    end
  end
end
