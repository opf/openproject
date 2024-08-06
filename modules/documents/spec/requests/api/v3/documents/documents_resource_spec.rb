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
require "rack/test"

RSpec.describe "API v3 documents resource" do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:document) { create(:document, project:) }
  let(:invisible_document) { create(:document, project: other_project) }
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i(view_documents) }

  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe "GET /api/v3/documents" do
    let(:path) { api_v3_paths.documents }

    before do
      document
      invisible_document

      get path
    end

    it "returns 200 OK" do
      expect(subject.status)
        .to be(200)
    end

    it "returns a Collection of visible documents" do
      expect(subject.body)
        .to be_json_eql("Collection".to_json)
        .at_path("_type")

      expect(subject.body)
        .to be_json_eql(1.to_json)
        .at_path("total")

      expect(subject.body)
        .to be_json_eql("Document".to_json)
        .at_path("_embedded/elements/0/_type")

      expect(subject.body)
        .to be_json_eql(document.title.to_json)
        .at_path("_embedded/elements/0/title")
    end
  end

  describe "GET /api/v3/documents/:id" do
    let(:path) { api_v3_paths.document(document.id) }

    before do
      get path
    end

    it "returns 200 OK" do
      expect(subject.status)
        .to be(200)
    end

    it "returns the document" do
      expect(subject.body)
        .to be_json_eql("Document".to_json)
        .at_path("_type")

      expect(subject.body)
        .to be_json_eql(document.id.to_json)
        .at_path("id")
    end

    context "when lacking permissions" do
      let(:permissions) { [] }

      it "returns 404 NOT FOUND" do
        expect(subject.status)
          .to be(404)
      end
    end
  end
end
