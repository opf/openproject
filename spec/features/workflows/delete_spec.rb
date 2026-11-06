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

require "spec_helper"

RSpec.describe "Workflows deletion happy path", :js do
  shared_let(:admin) { create(:admin) }

  shared_let(:replacement_flow) { create(:named_workflow, name: "Replacement flow") }
  shared_let(:source_flow) { create(:named_workflow, name: "Source flow") }

  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:base_variant) { bug.default_variant }
  shared_let(:named_variant) { create(:type_variant, type: bug, variant_name: "Hardware", workflow: source_flow) }

  before_all do
    base_variant.update!(workflow: source_flow)
  end

  current_user { admin }

  it "moves the types and variants to the chosen replacement, then deletes the workflow" do
    expect(base_variant.reload.workflow).to eq(source_flow)
    expect(named_variant.reload.workflow).to eq(source_flow)

    visit workflows_path

    within(page.find(".Box-row", text: "Source flow")) do
      click_button accessible_name: I18n.t("workflows.index.actions.menu", name: "Source flow")
      click_link_or_button I18n.t(:button_delete)
    end

    within("##{Workflows::Index::DeleteDialogComponent::DIALOG_ID}") do
      expect(page).to have_text(I18n.t("workflows.delete.body_in_use", count: 2))
      expect(page).to have_text(base_variant.composite_name)
      expect(page).to have_text(named_variant.composite_name)

      select "Replacement flow", from: I18n.t("workflows.delete.replace_label")
      check I18n.t("workflows.delete.confirmation_checkbox_label")
      click_link_or_button I18n.t("workflows.delete.button")
    end

    expect(page).to have_text(I18n.t(:notice_successful_delete))
    expect(page).to have_no_css(".Box-row .name a", text: "Source flow", exact_text: true)

    expect(Workflow.exists?(source_flow.id)).to be(false)
    expect(base_variant.reload.workflow).to eq(replacement_flow)
    expect(named_variant.reload.workflow).to eq(replacement_flow)
  end
end
