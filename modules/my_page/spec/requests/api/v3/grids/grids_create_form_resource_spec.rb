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

RSpec.describe "POST /api/v3/grids/form", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) do
    create(:project)
  end
  shared_let(:current_user) do
    create(:user,
           member_with_permissions: { project => %i[save_queries] })
  end

  let(:path) { api_v3_paths.create_grid_form }
  let(:params) { {} }

  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe "#post" do
    before do
      post path, params.to_json, "CONTENT_TYPE" => "application/json"
    end

    it "contains a Schema embedding the available values" do
      expect(subject.body)
        .to be_json_eql("Schema".to_json)
        .at_path("_embedded/schema/_type")

      expect(subject.body)
        .to be_json_eql(my_page_path.to_json)
        .at_path("_embedded/schema/scope/_links/allowedValues/0/href")
    end

    context "with /my/page for the scope value" do
      let(:params) do
        {
          _links: {
            scope: {
              href: my_page_path
            }
          }
        }
      end

      it "contains default data in the payload" do
        expected = {
          rowCount: 1,
          columnCount: 2,
          options: {},
          widgets: [
            {
              _type: "GridWidget",
              identifier: "work_packages_table",
              options: {
                name: "Work packages assigned to me",
                queryProps: {
                  "columns[]": %w(id project type subject),
                  filters: "[{\"status\":{\"operator\":\"o\",\"values\":[]}},{\"assigned_to\":{\"operator\":\"=\",\"values\":[\"me\"]}}]"
                }
              },
              startRow: 1,
              endRow: 2,
              startColumn: 1,
              endColumn: 2
            },
            {
              _type: "GridWidget",
              identifier: "work_packages_table",
              options: {
                name: "Work packages created by me",
                queryProps: {
                  "columns[]": %w(id project type subject),
                  filters: "[{\"status\":{\"operator\":\"o\",\"values\":[]}},{\"author\":{\"operator\":\"=\",\"values\":[\"me\"]}}]"
                }
              },
              startRow: 1,
              endRow: 2,
              startColumn: 2,
              endColumn: 3
            }
          ],
          _links: {
            attachments: [],
            scope: {
              href: "/my/page",
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

    context "with an unsupported widget identifier" do
      let(:params) do
        {
          _links: {
            scope: {
              href: my_page_path
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

    context "with name set" do
      let(:params) do
        {
          name: "My custom grid 1",
          _links: {
            scope: {
              href: my_page_path
            }
          }
        }
      end

      it "feeds it back" do
        expect(subject.body)
          .to be_json_eql("My custom grid 1".to_json)
          .at_path("_embedded/payload/name")
      end
    end

    context "with options set" do
      let(:params) do
        {
          options: {
            foo: "bar"
          },
          _links: {
            scope: {
              href: my_page_path
            }
          }
        }
      end

      it "feeds them back" do
        expect(subject.body)
          .to be_json_eql("bar".to_json)
          .at_path("_embedded/payload/options/foo")
      end
    end
  end
end
