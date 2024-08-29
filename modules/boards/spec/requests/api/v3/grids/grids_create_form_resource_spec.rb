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

RSpec.describe "POST /api/v3/grids/form for Board Grids", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) do
    create(:project)
  end

  let(:current_user) { allowed_user }
  let(:path) { api_v3_paths.create_grid_form }
  let(:params) { {} }

  shared_let(:current_user) do
    create(:user, member_with_permissions: { project => [:manage_board_views] })
  end

  shared_let(:prohibited_user) do
    create(:user, member_with_permissions: { project => [:show_board_views] })
  end

  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe "#post" do
    before do
      post path, params.to_json, "CONTENT_TYPE" => "application/json"
    end

    context "with a valid boards scope" do
      let(:params) do
        {
          name: "foo",
          _links: {
            scope: {
              href: project_work_package_boards_path(project)
            }
          }
        }
      end

      it "contains default data in the payload" do
        expected = {
          rowCount: 1,
          columnCount: 4,
          widgets: [],
          name: "foo",
          options: {},
          _links: {
            attachments: [],
            scope: {
              href: project_work_package_boards_path(project),
              type: "text/html"
            }
          }
        }

        expect(subject.body)
          .to be_json_eql(expected.to_json)
          .at_path("_embedded/payload")
      end

      it "has no validationErrors" do
        expect(subject.body)
          .to be_json_eql({}.to_json)
          .at_path("_embedded/validationErrors")
      end

      it "has a commit link" do
        expect(subject.body)
          .to be_json_eql(api_v3_paths.grids.to_json)
          .at_path("_links/commit/href")
      end
    end

    context "with boards scope for which the user does not have the necessary permissions" do
      let(:current_user) { prohibited_user }
      let(:params) do
        {
          _links: {
            scope: {
              href: project_work_package_boards_path(project)
            }
          }
        }
      end

      it "has a validationError on scope" do
        expect(subject.body)
          .to be_json_eql("Scope is not set to one of the allowed values.".to_json)
          .at_path("_embedded/validationErrors/scope/message")
      end
    end

    context "with an invalid boards scope" do
      let(:params) do
        {
          _links: {
            scope: {
              href: project_work_package_boards_path(project_id: project.id + 1)
            }
          }
        }
      end

      it "has a validationError on scope" do
        expect(subject.body)
          .to be_json_eql("Scope is not set to one of the allowed values.".to_json)
          .at_path("_embedded/validationErrors/scope/message")
      end
    end

    context "with an unsupported widget identifier" do
      let(:params) do
        {
          name: "foo",
          _links: {
            attachments: [],
            scope: {
              href: project_work_package_boards_path(project),
              type: "text/html"
            }
          },
          widgets: [
            {
              _type: "GridWidget",
              identifier: "bogus_identifier",
              startRow: 1,
              endRow: 2,
              startColumn: 1,
              endColumn: 2
            }
          ]
        }
      end

      it "has a validationError on widget" do
        expect(subject.body)
          .to be_json_eql("Widgets is not set to one of the allowed values.".to_json)
          .at_path("_embedded/validationErrors/widgets/message")
      end
    end
  end
end
