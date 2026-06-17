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

RSpec.describe "GET project overview", type: :rails_request do
  let(:project) { create(:project) }

  current_user { create(:admin) }

  shared_examples "includes canonical link tag" do
    it "renders a canonical link tag pointing to the current-identifier project URL" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<link rel="canonical" href="http://test.host/projects/#{project.identifier}">))
    end
  end

  context "when accessed via the numeric ID" do
    before { get "/projects/#{project.id}" }

    include_examples "includes canonical link tag"
  end

  context "when accessed via the string identifier" do
    before { get "/projects/#{project.identifier}" }

    include_examples "includes canonical link tag"
  end

  context "in semantic instance mode", with_settings: { work_packages_identifier: "semantic" } do
    let(:project) { create(:project, identifier: "PROJ") }

    context "when accessed via the semantic identifier" do
      before { get "/projects/#{project.identifier}" }

      include_examples "includes canonical link tag"
    end
  end
end
