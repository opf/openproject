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

require "spec_helper"

RSpec.describe "GET work package as Markdown", type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }

  current_user { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  it "renders the markdown export inline for the .md suffix" do
    get "/work_packages/#{work_package.id}.md"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/markdown")
    expect(response.headers["Content-Disposition"]).to eq(%(inline; filename="#{work_package.display_id}.md"))
    expect(response.body).to start_with("# #{work_package.type.name} #{work_package.formatted_id} - #{work_package.subject}\n")
  end

  it "renders the markdown export for Accept: text/markdown" do
    get "/work_packages/#{work_package.id}", headers: { "Accept" => "text/markdown" }

    expect(response.media_type).to eq("text/markdown")
  end

  it "answers project-scoped URLs directly without the html redirect" do
    get "/projects/#{project.identifier}/work_packages/#{work_package.id}.md"

    expect(response).to have_http_status(:ok)
  end

  it "returns 404 for a work package the user cannot see" do
    get "/work_packages/#{create(:work_package).id}.md"

    expect(response).to have_http_status(:not_found)
  end

  it "keeps the pdf export as an attachment" do
    get "/work_packages/#{work_package.id}.pdf"

    expect(response.headers["Content-Disposition"]).to start_with("attachment")
  end
end
