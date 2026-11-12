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

RSpec.describe Admin::ScimClients::TokenTableComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:scim_client) { create(:scim_client, :oauth2_token) }

  subject(:rendered_component) do
    render_component(rows: access_tokens)
  end

  shared_examples_for "rendering Border Box Grid headings" do
    include_examples "rendering Border Box Grid heading", text: "Created on"
    include_examples "rendering Border Box Grid heading", text: "Expires on"
    include_examples "rendering Border Box Grid mobile heading", text: "Access token table"
  end

  context "with no access tokens" do
    let(:access_tokens) { [] }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Blank Slate", heading: "No tokens have been created yet"
  end

  context "with access token" do
    let(:access_tokens) do
      [scim_client.oauth_application.access_tokens.create!(expires_in: 30),
       scim_client.oauth_application.access_tokens.create!(expires_in: 45)]
    end

    it_behaves_like "rendering Box", row_count: 2
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Border Box Grid rows", row_count: 2, col_count: 2
  end
end
