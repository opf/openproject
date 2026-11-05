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

RSpec.describe "Test management CI connections (project settings)", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:ci_admin) { create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_ci] }) }
  shared_let(:tm_admin) do
    create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_management] })
  end

  let(:current_user) { ci_admin }
  let(:settings_path) { project_test_management_project_settings_path(project) }
  let(:connections_path) { "/projects/#{project.identifier}/test_management/project_settings/ci_connections" }

  before { login_as(current_user) }

  def create_connection(**attrs)
    post connections_path, params: { ci_connection: { name: "Shop", provider: "github", repository: "my-org/shop",
                                                      ingest_mode: "new_iteration", target_run_name: "Smoke",
                                                      token: "ghp_secret_token_value", active: "1" }.merge(attrs) }
  end

  it "creates several connections; the token is stored encrypted and never rendered" do
    create_connection
    expect(response).to have_http_status(:see_other)
    create_connection(name: "Mobile", repository: "my-org/mobile", ingest_mode: "new_run", target_run_name: "", token: "")

    connections = TestManagement::CiConnection.where(project_id: project.id).order(:id)
    expect(connections.map(&:name)).to eq(%w[Shop Mobile])
    expect(connections.first.decrypted_token).to eq("ghp_secret_token_value")
    expect(connections.second).not_to be_token_set

    get settings_path
    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include("tm-ci-row-#{connections.first.id}", "tm-ci-row-#{connections.second.id}")
    expect(body).not_to include("ghp_secret_token_value")
    expect(body).not_to include(connections.first.token_ciphertext)
  end

  it "keeps the token when the field is left empty, replaces or removes it on request" do
    create_connection
    connection = TestManagement::CiConnection.last
    path = "#{connections_path}/#{connection.id}"

    patch path, params: { ci_connection: { name: "Shop web", token: "" } }
    expect(connection.reload).to have_attributes(name: "Shop web", decrypted_token: "ghp_secret_token_value")

    patch path, params: { ci_connection: { token: "ghp_new" } }
    expect(connection.reload.decrypted_token).to eq("ghp_new")

    patch path, params: { ci_connection: { remove_token: "1" } }
    expect(connection.reload).not_to be_token_set
  end

  it "shows validation errors and deletes connections" do
    create_connection(target_run_name: "")
    expect(flash[:error]).to be_present
    expect(TestManagement::CiConnection.count).to eq(0)

    create_connection
    delete "#{connections_path}/#{TestManagement::CiConnection.last.id}"
    expect(response).to have_http_status(:see_other)
    expect(TestManagement::CiConnection.count).to eq(0)
  end

  it "refuses every change while CI is switched off" do
    create(:tm_project_setting, project:, options: { "enable_ci" => false })

    create_connection

    expect(response).to have_http_status(:forbidden)
    expect(TestManagement::CiConnection.count).to eq(0)
  end

  it "does not reach connections of another project" do
    other = create(:tm_ci_connection)

    patch "#{connections_path}/#{other.id}", params: { ci_connection: { name: "Hijack" } }

    expect(response).to have_http_status(:not_found)
    expect(other.reload.name).not_to eq("Hijack")
  end

  context "with manage_test_management only" do
    let(:current_user) { tm_admin }

    it "hides the connections and refuses changes" do
      create(:tm_ci_connection, project:, name: "Shop")

      get settings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('data-test-selector="tm-ci-connections"')

      create_connection(name: "Other", repository: "my-org/other")
      expect(response).to have_http_status(:forbidden)
    end
  end
end
