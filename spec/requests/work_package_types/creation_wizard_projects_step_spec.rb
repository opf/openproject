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

RSpec.describe "Projects step of the type creation wizard", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Incident") }
  shared_let(:plant) { create(:project, name: "Plant", types: [type]) }
  shared_let(:office) { create(:project, name: "Office", types: [type]) }

  let(:back_url) { types_path }

  before { login_as admin }

  def query_of(href) = Rack::Utils.parse_query(URI.parse(href).query)

  context "with more projects than fit a page", with_settings: { per_page_options: "1, 100" } do
    it "pages through the projects without leaving the wizard" do
      get type_creation_wizard_path(type, step: :projects, back_url:, per_page: 1)

      href = page.find_link("2")[:href]

      expect(URI.parse(href).path).to eq(type_creation_wizard_path(type))
      expect(query_of(href)).to include("step" => "projects", "back_url" => back_url, "page" => "2")
    end
  end

  it "narrows the table by name" do
    get projects_type_creation_wizard_path(type, filters: %(name_and_identifier ~ "Off")), as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Office")
    expect(response.body).not_to include("Plant")
  end

  # Turbo follows the redirect after "Continue" on the previous step asking for a stream first.
  it "renders the whole step when arriving from the previous one" do
    get type_creation_wizard_path(type, step: :projects),
        headers: { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/html")
  end

  it "routes the tab's actions back to the wizard" do
    get type_creation_wizard_path(type, step: :projects)

    %w[type-projects-add-button type-projects-enable-all].each do |selector|
      hrefs = page.all(:test_id, selector).pluck(:href)

      expect(hrefs).to be_present.and(all(satisfy { |href| query_of(href)["wizard"] == "true" }))
    end
  end

  describe "a change made through the tab from the wizard" do
    it "reloads the wizard step instead of streaming in the tab's table" do
      delete unlink_type_projects_path(type_id: type.id, project_id: plant.id, wizard: true), as: :turbo_stream

      expect(response.body).to include("dispatchEvent")
      expect(response.body).not_to include("project-table")
    end

    it "keeps the tab streaming its own table" do
      delete unlink_type_projects_path(type_id: type.id, project_id: plant.id), as: :turbo_stream

      expect(response.body).to include("project-table")
      expect(response.body).not_to include("dispatchEvent")
    end
  end
end
