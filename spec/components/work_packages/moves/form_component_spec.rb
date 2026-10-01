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

RSpec.describe WorkPackages::Moves::FormComponent, type: :component do
  include OpenProject::StaticRouting::UrlHelpers

  subject(:rendered_component) do
    with_controller_class(WorkPackages::MovesController) do
      with_request_url("/work_packages/move/new") do
        render_inline(component)
      end
    end
  end

  let(:component) { build_component }
  let(:type) { create(:type, name: "Bug") }
  let(:project) { create(:project, types: [type]) }
  let(:target_project) { create(:project, types: [type]) }
  let(:work_package) { create(:work_package, project:, type:) }
  let(:status) { create(:status) }
  let!(:priority) { create(:priority, name: "High") }
  let(:version) { create(:version, project: target_project) }
  let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
  let(:user) { create(:user, member_with_roles: { project => role, target_project => role }) }

  def build_component(**params)
    described_class.new(
      work_packages: [work_package],
      project:,
      target_project:,
      notes: "Move notes",
      selected_values: { type_id: type.id.to_s },
      current_user: user,
      **params
    )
  end

  it "renders the move form" do
    expect(rendered_component).to have_css("form#move_form")
    expect(rendered_component).to have_field(:"ids[]", type: :hidden, with: work_package.id.to_s)
    expect(rendered_component).to have_select(:new_type_id, selected: type.name)
    expect(rendered_component).to have_field(:notes, with: "Move notes")
  end

  it "defaults the version select to '(no change)' when nothing is selected" do
    expect(rendered_component).to have_select("target_version_ids[]", selected: I18n.t(:label_no_change_option))
  end

  it "defaults the observed-in-versions select to '(no change)' when nothing is selected" do
    expect(rendered_component).to have_select("observed_in_version_ids[]", selected: I18n.t(:label_no_change_option))
  end

  it "wires the refresh-on-form-changes controller" do
    expect(rendered_component).to have_css(
      "form[data-controller='refresh-on-form-changes']" \
      "[data-refresh-on-form-changes-target='form']" \
      "[data-refresh-on-form-changes-turbo-stream-url-value='/work_packages/move/refresh_form']"
    )
  end

  context "with selected values" do
    let!(:workflow) { create(:workflow, type:, role:, old_status: work_package.status, new_status: status) }

    let(:component) do
      build_component(
        selected_values: {
          status_id: status.id.to_s,
          target_version_ids: [version.id.to_s],
          priority_id: priority.id.to_s
        }
      )
    end

    it "preserves the selected form values" do
      expect(rendered_component).to have_select(:status_id, selected: status.name)
      expect(rendered_component).to have_select("target_version_ids[]", selected: version.name)
      expect(rendered_component).to have_select(:priority_id, selected: priority.name)
    end
  end

  context "with multiple selected versions" do
    let!(:other_version) { create(:version, project: target_project, name: "Other version") }

    let(:component) do
      build_component(
        selected_values: {
          type_id: type.id.to_s,
          target_version_ids: [version.id.to_s, other_version.id.to_s]
        }
      )
    end

    it "preserves every selected version so a refresh does not reset the multi-select" do
      expect(rendered_component)
        .to have_select("target_version_ids[]", selected: [version.name, other_version.name])
    end
  end

  context "with a selected observed-in version" do
    let(:component) do
      build_component(selected_values: { observed_in_version_ids: [version.id.to_s] })
    end

    it "preserves the selected value" do
      expect(rendered_component).to have_select("observed_in_version_ids[]", selected: version.name)
    end
  end

  context "with a closed observed-in version" do
    let!(:closed_version) { create(:version, project: target_project, name: "Closed version", status: "closed") }

    it "offers closed versions, unlike the target-version select" do
      expect(rendered_component).to have_select("observed_in_version_ids[]", with_options: [closed_version.name])
      expect(rendered_component).to have_no_select("target_version_ids[]", with_options: [closed_version.name])
    end
  end

  context "when the user's roles differ between source and target project" do
    let(:source_status) { create(:status, name: "Source only") }
    let(:target_status) { create(:status, name: "Target only") }
    let(:source_role) { create(:project_role, permissions: %i[view_work_packages]) }
    let(:target_role) { create(:project_role, permissions: %i[view_work_packages]) }
    let(:user) do
      create(:user, member_with_roles: { project => source_role, target_project => target_role })
    end

    before do
      create(:workflow, type:, role: source_role, old_status: work_package.status, new_status: source_status)
      create(:workflow, type:, role: target_role, old_status: work_package.status, new_status: target_status)
    end

    it "offers the statuses available in the target project" do
      expect(rendered_component).to have_select(:status_id, with_options: [target_status.name])
      expect(rendered_component).to have_no_select(:status_id, with_options: [source_status.name])
    end
  end

  context "with a required custom field on the target type" do
    let!(:custom_field) do
      create(:string_wp_custom_field,
             name: "Risk score",
             is_required: true,
             types: [type],
             projects: [project, target_project])
    end

    it "renders the required marker as an HTML element, not escaped text" do
      expect(rendered_component).to have_css("label.form--label span.required", text: "*")
      expect(rendered_component).to have_no_text('<span class="required">')
    end
  end

  context "when a moved work package's current type is unavailable in the target project" do
    let(:other_type) { create(:type, name: "Phase") }
    let(:project) { create(:project, types: [other_type]) }
    let(:target_project) { create(:project, types: [type]) }
    let(:work_package) { create(:work_package, project:, type: other_type) }

    it "renders the unavailable-type warning" do
      expect(rendered_component)
        .to have_css(".op-toast.-warning",
                     text: I18n.t("work_packages.move.current_type_not_available_in_target_project"))
    end
  end

  context "when a descendant's type is unavailable in the target project" do
    let(:child_type) { create(:type, name: "Phase") }
    let(:project) { create(:project, types: [type, child_type]) }

    before do
      create(:work_package, project:, type: child_type, parent: work_package)
    end

    it "renders the unavailable-type warning" do
      expect(rendered_component)
        .to have_css(".op-toast.-warning",
                     text: I18n.t("work_packages.move.current_type_not_available_in_target_project"))
    end
  end

  context "when all moved work package types exist in the target project" do
    it "does not render the unavailable-type warning" do
      expect(rendered_component).to have_no_css(".op-toast.-warning")
    end
  end

  context "with a required project-scoped custom field on the target type" do
    let!(:source_version) { create(:version, project:, name: "Source milestone") }
    let!(:target_version) { create(:version, project: target_project, name: "Target milestone") }
    let!(:custom_field) do
      create(:version_wp_custom_field,
             name: "Milestone",
             is_required: true,
             types: [type],
             projects: [project, target_project])
    end

    it "scopes the custom field options to the target project" do
      cf_select = "custom_field_values[#{custom_field.id}]"

      expect(rendered_component).to have_select(cf_select, with_options: ["Target milestone"])
      expect(rendered_component).to have_no_select(cf_select, with_options: ["Source milestone"])
    end
  end
end
