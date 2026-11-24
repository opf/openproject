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
require "rack/test"

RSpec.describe "API v3 work package security levels", content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:scheme) { create(:security_level_scheme) }
  shared_let(:project) { create(:project, security_level_scheme: scheme) }
  shared_let(:internal) { create(:security_level, security_level_scheme: scheme, name: "Internal") }
  shared_let(:management) { create(:security_level, security_level_scheme: scheme, name: "Management") }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_work_packages edit_work_packages set_work_package_security_level]
           })
  end

  let(:work_package) { create(:work_package, project:) }

  current_user { user }

  before { SecurityLevelPrincipal.create!(security_level: internal, principal: user) }

  it "hides work packages of levels the user does not hold" do
    secret = create(:work_package, project:, security_level: management)

    get api_v3_paths.work_package(secret.id)

    expect(last_response).to have_http_status(:not_found)
  end

  it "renders the level of a visible work package" do
    work_package.update_column(:security_level_id, internal.id)

    get api_v3_paths.work_package(work_package.id)

    expect(last_response.body)
      .to be_json_eql(api_v3_paths.security_level(internal.id).to_json)
      .at_path("_links/securityLevel/href")
  end

  it "offers the levels the user holds in the schema" do
    post api_v3_paths.work_package_form(work_package.id), { lockVersion: work_package.lock_version }.to_json

    expect(last_response.body).to have_json_path("_embedded/schema/securityLevel")
    expect(last_response.body).to be_json_eql(true.to_json).at_path("_embedded/schema/securityLevel/writable")
    expect(last_response.body).to have_json_size(1).at_path("_embedded/schema/securityLevel/_links/allowedValues")
  end

  it "sets the level" do
    patch api_v3_paths.work_package(work_package.id),
          { lockVersion: work_package.lock_version,
            _links: { securityLevel: { href: api_v3_paths.security_level(internal.id) } } }.to_json

    expect(last_response).to have_http_status(:ok)
    expect(work_package.reload.security_level).to eq internal
  end

  it "clears the level" do
    work_package.update_column(:security_level_id, internal.id)

    patch api_v3_paths.work_package(work_package.id),
          { lockVersion: work_package.lock_version, _links: { securityLevel: { href: nil } } }.to_json

    expect(last_response).to have_http_status(:ok)
    expect(work_package.reload.security_level).to be_nil
  end

  it "renders a level" do
    get api_v3_paths.security_level(internal.id)

    expect(last_response).to have_http_status(:ok)
    expect(last_response.body).to be_json_eql("SecurityLevel".to_json).at_path("_type")
    expect(last_response.body).to be_json_eql("Internal".to_json).at_path("name")
  end
end
