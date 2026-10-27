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

RSpec.describe "GET work package as Markdown", type: :rails_request do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  context "when logged in" do
    before { login_as user }

    it "renders the markdown export inline for the .md suffix" do
      get "/work_packages/#{work_package.id}.md"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/markdown")
      expect(response.headers["Content-Type"]).to eq("text/markdown; charset=utf-8")
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

    it "ignores a current_user query parameter" do
      work_package.update!(description: "Hello workPackageValue:subject")

      get "/work_packages/#{work_package.id}.md?current_user=bogus"

      expect(response).to have_http_status(:ok)
      expect(response.body).to end_with("Hello #{work_package.subject}\n")
    end

    it "returns 404 for a work package the user cannot see" do
      get "/work_packages/#{create(:work_package).id}.md"

      expect(response).to have_http_status(:not_found)
    end

    context "with the permission to export work packages" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_work_packages export_work_packages] })
      end

      it "keeps the pdf export as an attachment" do
        get "/work_packages/#{work_package.id}.pdf"

        expect(response.headers["Content-Disposition"]).to start_with("attachment")
      end
    end
  end

  context "with an expired browser session",
          :skip_csrf,
          with_settings: { session_ttl_enabled?: true, session_ttl: "120" } do
    it "logs the user out and redirects to the login page" do
      post "/login", params: { username: user.login, password: "adminADMIN!" }
      follow_redirect! while response.redirect?
      expect(session[:user_id]).to eq(user.id)

      travel 3.hours
      get "/work_packages/#{work_package.id}.md"

      expect(response).to redirect_to(%r{/login})
    end
  end
end
