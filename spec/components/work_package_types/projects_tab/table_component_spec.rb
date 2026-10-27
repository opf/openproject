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

RSpec.describe WorkPackageTypes::ProjectsTab::TableComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:hardware) { create(:type_variant, type:, variant_name: "Hardware") }

  shared_let(:on_base) { create(:project, name: "Bookshop", types: [type]) }
  shared_let(:on_hardware) { create(:project, name: "Foundry", types: [hardware]) }
  shared_let(:archived) { create(:project, name: "Attic", active: false, types: [type]) }
  shared_let(:owning) { create(:project, name: "Laboratory") }
  shared_let(:owned) { create(:project_owned_type_variant, type:, project: owning, variant_name: "Firmware") }

  before_all do
    create(:project_type, project: owning, type:, variant: owned)
  end

  let(:projects) { Project.where(id: [on_base, on_hardware, archived, owning]) }
  let(:filtered) { false }
  let(:base_row) { find_test_selector("type-projects-row-#{on_base.id}") }
  let(:hardware_row) { find_test_selector("type-projects-row-#{on_hardware.id}") }
  let(:archived_row) { find_test_selector("type-projects-row-#{archived.id}") }
  let(:owning_row) { find_test_selector("type-projects-row-#{owning.id}") }

  subject(:rendered_component) do
    with_request_url "/types/#{type.id}/projects/edit" do
      render_inline(
        described_class.new(rows: projects.paginate(page: 1, per_page: 10), variant: type.default_variant, filtered:)
      )
    end
  end

  before { rendered_component }

  it "links each project" do
    expect(base_row).to have_link("Bookshop", href: project_path(on_base))
  end

  it "labels archived projects" do
    expect(archived_row).to have_css(".Label", text: I18n.t("project.archive.archived"))
    expect(base_row).to have_no_css(".Label")
  end

  it "names the type without a caption for projects on the default variant" do
    expect(base_row).to have_text("Bug")
    expect(base_row).to have_no_css(".color-fg-muted", exact_text: I18n.t("types.index.variant_label"))
  end

  it "captions a global variant as a variant" do
    expect(hardware_row).to have_text("Hardware")
    expect(hardware_row).to have_css(".color-fg-muted", exact_text: I18n.t("types.index.variant_label"))
  end

  it "captions a project's own variant as project-specific" do
    expect(owning_row).to have_text("Firmware")
    expect(owning_row)
      .to have_css(".color-fg-muted", exact_text: I18n.t("projects.settings.types.project_specific_variant"))
  end

  context "without any project" do
    let(:projects) { Project.none }

    it "invites adding one" do
      expect(page).to have_text(I18n.t("types.edit.projects.empty_state.title"))
      expect(page).to have_text(I18n.t("types.edit.projects.empty_state.description"))
    end

    context "when filtered" do
      let(:filtered) { true }

      it "says nothing matched instead" do
        expect(page).to have_text(I18n.t("types.edit.projects.empty_state.no_results"))
        expect(page).to have_no_text(I18n.t("types.edit.projects.empty_state.description"))
      end
    end
  end
end
