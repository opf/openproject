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

RSpec.describe "API v3 User resource",
               content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:current_user) { create(:user) }
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:locked_admin) { create(:admin, status: Principal.statuses[:locked]) }
  let(:user_with_global_manage_user) do
    create(:user, firstname: "Global", lastname: "User", global_permissions: [:manage_user])
  end

  subject(:response) { last_response }

  before do
    login_as(current_user)
  end

  describe "#index" do
    let(:get_path) { api_v3_paths.path_for(:users, sort_by: [%i[id asc]]) }

    before do
      user
      get get_path
    end

    shared_examples "flow with permitted user" do
      it "responds with 200" do
        expect(subject.status).to eq(200)
      end

      # note that the order of the users is depending on the id
      # meaning the order in which they where saved
      it "contains the user in the response" do
        expect(subject.body)
          .to be_json_eql(current_user.name.to_json)
          .at_path("_embedded/elements/0/name")
      end

      it "contains the current user in the response" do
        expect(subject.body)
          .to be_json_eql(user.name.to_json)
          .at_path("_embedded/elements/1/name")
      end

      it "has the users index path for link self href" do
        expect(subject.body)
          .to be_json_eql("#{api_v3_paths.users}?filters=%5B%5D" \
                          "\u0026offset=1\u0026pageSize=20\u0026sortBy=%5B%5B%22id%22%2C%22asc%22%5D%5D".to_json)
          .at_path("_links/self/href")
      end

      context "if pageSize = 1 and offset = 2" do
        let(:get_path) { api_v3_paths.path_for(:users, page_size: 1, offset: 2) }

        it "contains the current user in the response" do
          expect(subject.body)
            .to be_json_eql(current_user.name.to_json)
            .at_path("_embedded/elements/0/name")
        end
      end

      context "when filtering by name" do
        let(:get_path) do
          filter = [{ "name" => {
            "operator" => "~",
            "values" => [user.name]
          } }]

          "#{api_v3_paths.users}?#{{ filters: filter.to_json }.to_query}"
        end

        it "contains the filtered user in the response" do
          expect(subject.body)
            .to be_json_eql(user.name.to_json)
            .at_path("_embedded/elements/0/name")
        end

        it "contains no more users" do
          expect(subject.body)
            .to be_json_eql(1.to_json)
            .at_path("total")
        end
      end

      context "when sorting" do
        let(:users_by_name_order) do
          User.human.ordered_by_name(desc: true)
        end

        let(:get_path) do
          sort = [%w[name desc]]

          "#{api_v3_paths.users}?#{{ sortBy: sort.to_json }.to_query}"
        end

        it "contains the first user as the first element" do
          expect(subject.body)
            .to be_json_eql(users_by_name_order[0].name.to_json)
            .at_path("_embedded/elements/0/name")
        end

        it "contains the first user as the second element" do
          expect(subject.body)
            .to be_json_eql(users_by_name_order[1].name.to_json)
            .at_path("_embedded/elements/1/name")
        end
      end

      context "with an invalid filter" do
        let(:get_path) do
          filter = [{ "name" => {
            "operator" => "a",
            "values" => [user.name]
          } }]

          "#{api_v3_paths.users}?#{{ filters: filter.to_json }.to_query}"
        end

        it "returns an error" do
          expect(subject.status).to be(400)
        end
      end

      context "when signaling desired properties" do
        let(:get_path) do
          api_v3_paths.path_for :users,
                                sort_by: [%w[name desc]],
                                page_size: 1,
                                select: "total,elements/name"
        end

        let(:expected) do
          {
            total: 2,
            _embedded: {
              elements: [
                {
                  name: current_user.name
                }
              ]
            }
          }
        end

        it "returns an error" do
          expect(subject.body)
            .to be_json_eql(expected.to_json)
        end
      end
    end

    context "for an admin" do
      let(:current_user) { admin }

      it_behaves_like "flow with permitted user"
    end

    context "for a user with global manage_user permission" do
      let(:current_user) { user_with_global_manage_user }

      it_behaves_like "flow with permitted user"
    end

    context "for a locked admin" do
      let(:current_user) { locked_admin }

      it_behaves_like "unauthorized access"
    end

    context "for another user" do
      it_behaves_like "unauthorized access"
    end
  end

  describe "#get" do
    let(:get_path) { api_v3_paths.user user.id }

    before do
      get get_path
    end

    context "logged in user" do
      it "responds with 200" do
        expect(subject.status).to eq(200)
      end

      it "responds with correct body" do
        expect(subject.body).to be_json_eql(user.name.to_json).at_path("name")
      end

      context "requesting nonexistent user" do
        let(:get_path) { api_v3_paths.user 9999 }

        it_behaves_like "not found"
      end

      context "requesting current user" do
        let(:get_path) { api_v3_paths.user "me" }

        it "responses with 200" do
          expect(subject.status).to eq(200)
          expect(subject.body).to be_json_eql(user.name.to_json).at_path("name")
        end
      end
    end

    context "get with login" do
      let(:get_path) { api_v3_paths.user user.login }

      it "responds with 200" do
        expect(subject.status).to eq(200)
      end

      it "responds with correct body" do
        expect(subject.body).to be_json_eql(user.name.to_json).at_path("name")
      end
    end

    it_behaves_like "handling anonymous user" do
      let(:path) { api_v3_paths.user user.id }
    end
  end

  describe "#delete" do
    let(:path) { api_v3_paths.user user.id }
    let(:admin_delete) { true }
    let(:self_delete) { true }

    before do
      allow(Setting).to receive(:users_deletable_by_admins?).and_return(admin_delete)
      allow(Setting).to receive(:users_deletable_by_self?).and_return(self_delete)

      delete path
      user.reload
    end

    shared_examples "deletion allowed" do
      it "responds with 202" do
        expect(subject.status).to eq 202
      end

      it "locks the account and mark for deletion" do
        expect(Principals::DeleteJob)
          .to have_been_enqueued
          .with(user)

        expect(user).to be_locked
      end

      context "with a non-existent user" do
        let(:path) { api_v3_paths.user 1337 }

        it_behaves_like "not found"
      end
    end

    shared_examples "deletion is not allowed" do
      it_behaves_like "unauthorized access"

      it "does not delete the user" do
        expect(User).to exist(user.id)
      end
    end

    context "as admin" do
      let(:current_user) { admin }

      context "with users deletable by admins" do
        let(:admin_delete) { true }

        it_behaves_like "deletion allowed"
      end

      context "with users not deletable by admins" do
        let(:admin_delete) { false }

        it_behaves_like "deletion is not allowed"
      end
    end

    context "as locked admin" do
      let(:current_user) { locked_admin }

      it_behaves_like "deletion is not allowed"
    end

    context "as non-admin" do
      let(:current_user) { create(:user, admin: false) }

      it_behaves_like "deletion is not allowed"
    end

    context "as user with manage_user permission" do
      let(:current_user) { user_with_global_manage_user }

      it_behaves_like "deletion is not allowed"
    end

    context "as self" do
      let(:current_user) { user }

      context "with self-deletion allowed" do
        let(:self_delete) { true }

        it_behaves_like "deletion allowed"
      end

      context "with self-deletion not allowed" do
        let(:self_delete) { false }

        it_behaves_like "deletion is not allowed"
      end
    end

    context "as anonymous user" do
      let(:current_user) { create(:anonymous) }

      context "when login_required", with_settings: { login_required: true } do
        it_behaves_like "error response",
                        401,
                        "Unauthenticated",
                        I18n.t("api_v3.errors.code_401")
      end

      context "when not login_required", with_settings: { login_required: false } do
        it_behaves_like "deletion is not allowed"
      end

      context "requesting current user" do
        let(:get_path) { api_v3_paths.user "me" }

        it_behaves_like "forbidden response based on login_required"
      end
    end
  end
end
