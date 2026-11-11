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

RSpec.describe SquashTMIntegration::ProjectSettings::StatusBannerComponent, type: :component do
  let(:server) { build_stubbed(:squashtm_server) }
  let(:project_link) { build(:squashtm_project_link, squashtm_project_id: 7, squashtm_project_name: "Sandbox") }
  let(:squashtm_projects) { [{ id: 7, name: "Sandbox" }] }

  subject(:rendered) do
    render_inline(described_class.new(server:, project_link:, squashtm_projects:))
  end

  context "without a server" do
    let(:server) { nil }

    it "reports that no server is configured" do
      expect(rendered).to have_css("[data-test-selector='squashtm--no-server']")
    end
  end

  context "when the SquashTM projects could not be loaded" do
    let(:squashtm_projects) { nil }

    it "reports that the projects are unavailable" do
      expect(rendered).to have_css("[data-test-selector='squashtm--projects-unavailable']")
    end
  end

  context "with a persisted link whose project is not in the list" do
    let(:project_link) { create(:squashtm_project_link, squashtm_project_id: 7, squashtm_project_name: "Gone") }
    let(:squashtm_projects) { [{ id: 8, name: "Another project" }] }

    it "reports the stored project as missing, even after a rejected change" do
      project_link.squashtm_project_id = 8

      expect(rendered).to have_css("[data-test-selector='squashtm--linked-project-missing']", text: "Gone")
    end
  end

  context "with a persisted link whose project is in the list" do
    let(:project_link) { create(:squashtm_project_link, squashtm_project_id: 7) }

    it "renders nothing" do
      expect(rendered.to_html).to be_blank
    end
  end

  context "with an unsaved link" do
    let(:squashtm_projects) { [{ id: 8, name: "Another project" }] }

    it "renders nothing" do
      expect(rendered.to_html).to be_blank
    end
  end
end
