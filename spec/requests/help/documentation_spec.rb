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

RSpec.describe "Embedded documentation", type: :rails_request do
  current_user { create(:user) }

  it "returns the article in the matching Turbo frame without project permissions", :aggregate_failures do
    get documentation_article_help_path(article_id: "initiation-request", context: "initiation")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(Help::DocumentationDialogComponent.frame_id("initiation"))
    expect(response.body).to include(Help::DocumentationArticle.new("initiation-request").title)
  end

  it "rejects an unknown article" do
    get documentation_article_help_path(article_id: "not-an-article")
    expect(response).to have_http_status(:not_found)
  end

  it "rejects arbitrary image filenames" do
    get documentation_asset_help_path(article_id: "project-life-cycle", filename: "README.md")
    expect(response).to have_http_status(:not_found)
  end

  it "serves a figure referenced by the selected article" do
    get documentation_asset_help_path(article_id: "project-life-cycle",
                                      filename: "openproject_user_guide_project_home_page_project_lifecycle.png")
    expect(response).to have_http_status(:ok)
  end
end
