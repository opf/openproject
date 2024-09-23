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

RSpec.describe "POST /projects/:project_id/ifc_models/set_direct_upload_file_name" do
  shared_let(:user) { create(:admin, preferences: { time_zone: "Etc/UTC" }) }
  let(:project) { build_stubbed(:project) }

  context "when user is not logged in" do
    it "requires login" do
      post set_direct_upload_file_name_bcf_project_ifc_models_path(project_id: project.id)
      expect(last_response).to have_http_status(:not_acceptable)
    end
  end

  context "when user is logged in" do
    before { login_as(user) }

    context "and the upload exceeds the maximum size", with_settings: { attachment_max_size: 1 } do
      it "returns a 422" do
        post set_direct_upload_file_name_bcf_project_ifc_models_path(project_id: project.id),
             { title: "Test.ifc", isDefault: "0", filesize: "113328073" }
        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(parse_json(last_response.body)).to eq({ "error" => "is too large (maximum size is 1024 Bytes)." })
      end
    end
  end
end
