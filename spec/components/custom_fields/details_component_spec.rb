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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe CustomFields::DetailsComponent, type: :component do
  subject(:rendered) { render_inline(described_class.new(custom_field, form_url: "/custom_fields")) }

  let(:banner) { "Remember to set items for this custom field, and to make sure it is used in at least one project." }

  current_user { create(:admin) }

  describe "the reminder banner for a list custom field without options" do
    let(:type) { create(:type) }
    let(:custom_field) { create(:list_wp_custom_field, possible_values: [], types: [type]) }

    context "when no project uses the type carrying it" do
      it "reminds, since the field can appear nowhere" do
        expect(rendered.to_html).to include(banner)
      end
    end

    context "when a project uses the type carrying it" do
      before { create(:project, types: [type]) }

      it "does not remind" do
        expect(rendered.to_html).not_to include(banner)
      end
    end

    context "when the field is on no type at all" do
      let(:custom_field) { create(:list_wp_custom_field, possible_values: []) }

      it "reminds" do
        expect(rendered.to_html).to include(banner)
      end
    end
  end

  describe "the warning when switching how project-specific values are chosen" do
    let(:banner_for) { ->(mode) { rendered.css("[data-test-selector='project-specific-values-switch-to-#{mode}']") } }

    context "when values are activated for each project" do
      let(:custom_field) { create(:list_wp_custom_field, :project_specific_allowlist) }

      it "prepares a hidden warning for switching to each other option" do
        expect(banner_for.call("allow")).to be_empty

        expect(banner_for.call("all").attr("hidden")).to be_present
        expect(banner_for.call("all").attr("data-value").value).to eq("")
        expect(banner_for.call("all").text).to include(I18n.t("custom_fields.project_specific_values.switch_warning.all"))

        expect(banner_for.call("block").attr("hidden")).to be_present
        expect(banner_for.call("block").attr("data-value").value).to eq("block")
        expect(banner_for.call("block").text).to include(I18n.t("custom_fields.project_specific_values.switch_warning.block"))
      end
    end

    context "when the same values are shown for all projects" do
      let(:custom_field) { create(:list_wp_custom_field) }

      it "prepares a hidden warning for switching to each other option" do
        expect(banner_for.call("all")).to be_empty
        expect(banner_for.call("allow").text).to include(I18n.t("custom_fields.project_specific_values.switch_warning.allow"))
        expect(banner_for.call("block").text).to include(I18n.t("custom_fields.project_specific_values.switch_warning.block"))
      end
    end

    context "when another option is selected but not yet saved" do
      let(:custom_field) do
        create(:list_wp_custom_field).tap { it.project_specific_value_restriction = "block" }
      end

      it "shows the warning for the selected option" do
        expect(banner_for.call("block").attr("hidden")).to be_nil
        expect(banner_for.call("allow").attr("hidden")).to be_present
      end
    end
  end

  describe "for a project custom field" do
    let(:custom_field) { create(:list_project_custom_field, possible_values: []) }

    it "reminds while it is mapped to no project" do
      expect(rendered.to_html).to include(banner)
    end

    context "when mapped to a project" do
      before { create(:project_custom_field_project_mapping, project_custom_field: custom_field) }

      it "does not remind" do
        expect(rendered.to_html).not_to include(banner)
      end
    end
  end
end
