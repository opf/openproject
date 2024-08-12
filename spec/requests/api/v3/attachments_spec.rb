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
require_relative "attachments/attachment_resource_shared_examples"

RSpec.describe API::V3::Attachments::AttachmentsAPI do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper
  include FileHelpers

  let(:current_user) { create(:user, member_with_roles: { project => role }) }

  let(:project) { create(:project, public: false) }
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { [:add_work_packages] }

  describe "permissions", :with_direct_uploads do
    let(:request_path) { api_v3_paths.prepare_new_attachment_upload }
    let(:request_parts) { { metadata: metadata.to_json, file: } }
    let(:metadata) { { fileName: "cat.png", fileSize: file.size, contentType: "image/png" } }
    let(:file) { mock_uploaded_file(name: "original-filename.txt") }

    before do
      allow(User).to receive(:current).and_return current_user
      post request_path, request_parts
    end

    context "with missing permissions" do
      let(:permissions) { [] }

      it "forbids to prepare attachments" do
        expect(last_response).to have_http_status :forbidden
      end
    end

    context "with :edit_work_packages permission" do
      let(:permissions) { [:edit_work_packages] }

      it "can prepare attachments" do
        expect(last_response).to have_http_status :created
      end
    end

    context "with :add_work_package_attachments permission" do
      let(:permissions) { [:add_work_package_attachments] }

      it "can prepare attachments" do
        expect(last_response).to have_http_status :created
      end
    end
  end

  it_behaves_like "it supports direct uploads" do
    let(:request_path) { api_v3_paths.prepare_new_attachment_upload }
    let(:container_href) { nil }

    describe "GET /uploaded" do
      let(:status) { :prepared }
      let(:attachment) do
        create(:attachment, status:, author: current_user, container: nil, container_type: nil)
      end

      before do
        get "/api/v3/attachments/#{attachment.id}/uploaded"
      end

      context "with no pending attachments" do
        let(:status) { :uploaded }

        it "returns 404" do
          expect(last_response).to have_http_status :not_found
        end
      end

      context "with a pending attachment" do
        it "enqueues a FinishDirectUpload job" do
          expect(Attachments::FinishDirectUploadJob).to have_been_enqueued.at_least(1)
        end

        it "responds with HTTP OK" do
          expect(last_response).to have_http_status :ok
        end

        it "returns the attachment representation" do
          json = JSON.parse last_response.body

          expect(json["_type"]).to eq "Attachment"
        end
      end
    end
  end

  context "with an quarantined attachments"
end
