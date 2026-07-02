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

RSpec.describe "GET work package show", type: :rails_request do
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }

  current_user { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  shared_examples "includes canonical link tag" do |tab: "activity"|
    it "renders a canonical link tag pointing to the current-identifier URL" do
      expect(response).to have_http_status(:ok)
      expected_path = "/projects/#{project.identifier}/work_packages/#{work_package.display_id}/#{tab}"
      expect(response.body).to include(%(<link rel="canonical" href="http://test.host#{expected_path}">))
    end
  end

  context "when accessed via the project-scoped URL" do
    before { get "/projects/#{project.id}/work_packages/#{work_package.id}/activity" }

    include_examples "includes canonical link tag"
  end

  context "when accessed via the project-scoped URL on the relations tab" do
    before { get "/projects/#{project.id}/work_packages/#{work_package.id}/relations" }

    include_examples "includes canonical link tag", tab: "relations"
  end

  context "when accessed via the global URL" do
    before do
      get "/work_packages/#{work_package.id}/activity"
      follow_redirect!
    end

    include_examples "includes canonical link tag"
  end

  context "when the work package does not exist" do
    before { get "/projects/#{project.id}/work_packages/0/activity" }

    it "renders a not-found response without raising" do
      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include(%(<link rel="canonical"))
    end
  end

  context "in semantic instance mode", with_settings: { work_packages_identifier: "semantic" } do
    let(:project) { create(:project, identifier: "PROJ") }
    let(:work_package) { create(:work_package, project:) }

    context "when accessed via the semantic ID" do
      before { get "/projects/#{project.id}/work_packages/#{work_package.identifier}/activity" }

      include_examples "includes canonical link tag"
    end
  end
end
