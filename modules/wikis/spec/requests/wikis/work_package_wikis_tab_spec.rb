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
require_module_spec_helper

RSpec.describe "Work package wikis tab", :skip_csrf, type: :rails_request do
  let(:permissions) { %i[view_work_packages view_wiki_pages] }
  let(:role) { create(:project_role, permissions:) }
  let(:user) { create(:user) }
  let(:project) { create(:project, :with_internal_wiki, members: { user => role }) }
  let(:provider) { Wikis::InternalProvider.first }
  let(:work_package) { create(:work_package, project:) }
  let(:wiki_page) { create(:wiki_page, wiki: project.wiki, title: "Architecture handbook") }

  before { login_as user }

  describe "GET /projects/:project_id/work_packages/:work_package_id/wikis/tab/inline_page_links" do
    subject(:send_request) do
      get inline_page_links_project_work_package_wikis_tab_index_path(
        project_id: project.id,
        work_package_id: work_package.id
      ), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    it "streams a replacement of the section, so that the rest of the tab is left alone", :aggregate_failures do
      send_request

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(target="#{Wikis::InlinePageLinksComponent.wrapper_key}"))
      expect(response.body).to include(%(action="replace"))
    end

    context "when the description mentions a wiki page" do
      let!(:inline_page_link) do
        create(:inline_wiki_page_link, linkable: work_package, provider:, identifier: wiki_page.id.to_s)
      end

      it "renders the mentioned page" do
        send_request

        expect(response.body).to include(wiki_page.title)
      end
    end

    context "without permission to view the work package" do
      let(:permissions) { %i[view_wiki_pages] }

      it "responds with forbidden" do
        send_request

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
