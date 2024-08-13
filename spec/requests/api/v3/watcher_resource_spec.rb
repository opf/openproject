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

RSpec.describe "API v3 Watcher resource", content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project, identifier: "test_project", public: false) }
  let(:current_user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { [] }
  let(:view_work_packages_role) { create(:project_role, permissions: [:view_work_packages]) }
  let(:work_package) { create(:work_package, project:) }
  let(:available_watcher) do
    create(:user,
           firstname: "Something",
           lastname: "Strange",
           member_with_roles: { project => view_work_packages_role })
  end

  let(:watching_user) do
    create(:user,
           member_with_roles: { project => view_work_packages_role })
  end
  let(:existing_watcher) do
    create(:watcher, watchable: work_package, user: watching_user)
  end

  let!(:watching_blocked_user) do
    create(:user,
           login: "lockedUser",
           mail: "lockedUser@gmail.com",
           member_with_roles: { project => view_work_packages_role })
  end
  let!(:existing_blocked_watcher) do
    create(:watcher, watchable: work_package, user: watching_blocked_user).tap do
      watching_blocked_user.locked!
    end
  end

  subject(:response) { last_response }

  before do
    allow(User).to receive(:current).and_return current_user
    existing_watcher
  end

  describe "#get" do
    let(:get_path) { api_v3_paths.work_package_watchers work_package.id }
    let(:permissions) { %i[view_work_packages view_work_package_watchers] }

    before do
      get get_path
    end

    it_behaves_like "API V3 collection response", 1, 1, "User"

    context "for a user not allowed to see watchers" do
      let(:permissions) { [:view_work_packages] }

      it_behaves_like "unauthorized access"
    end

    context "for a user not allowed to see work package" do
      let(:permissions) { [] }

      it_behaves_like "not found",
                      I18n.t("api_v3.errors.not_found.work_package")
    end
  end

  describe "#post" do
    let(:post_path) { api_v3_paths.work_package_watchers work_package.id }
    let(:post_body) do
      {
        user: { href: api_v3_paths.user(new_watcher.id) }
      }.to_json
    end
    let(:new_watcher) { available_watcher }

    let(:permissions) { %i[add_work_package_watchers view_work_packages] }

    before do
      perform_enqueued_jobs do
        post post_path, post_body
      end
    end

    it "responds with 201" do
      expect(subject.status).to eq(201)
    end

    it "responds with newly added watcher" do
      expect(subject.body).to be_json_eql("User".to_json).at_path("_type")
    end

    it "sends mails" do
      expect(ActionMailer::Base.deliveries.size)
        .to be 1

      expect(ActionMailer::Base.deliveries.map(&:to).flatten.uniq)
        .to match_array new_watcher.mail

      expect(ActionMailer::Base.deliveries.first.text_part.body.encoded)
        .to include I18n.t("text_work_package_watcher_added",
                           id: "##{work_package.id}",
                           watcher_changer: User.current)
    end

    context "when user is already watcher" do
      let(:new_watcher) { watching_user }

      it "responds with 200" do
        expect(subject.status).to eq(200)
      end

      it "responds with correct watcher" do
        expect(subject.body).to be_json_eql("User".to_json).at_path("_type")
      end
    end

    context "when the work package does not exist" do
      let(:post_path) { api_v3_paths.work_package_watchers 9999 }

      it_behaves_like "not found",
                      I18n.t("api_v3.errors.not_found.work_package")
    end

    context "when the user does not exist" do
      let(:post_body) do
        {
          user: { href: api_v3_paths.user(99999) }
        }.to_json
      end

      it_behaves_like "not found"
    end

    context "when the target user is not allowed to watch the work package" do
      let(:new_watcher) { create(:user) }

      it_behaves_like "constraint violation" do
        let(:message) { "User is not allowed to view this resource." }
      end
    end

    context "when the target user is locked" do
      let(:new_watcher) do
        user = create(:user,
                      member_with_roles: { project => view_work_packages_role })
        user.locked!
        user
      end

      it_behaves_like "constraint violation" do
        let(:message) { "User is locked." }
      end
    end

    context "for an unauthorized user" do
      context "when the current user is trying to assign another user as watcher" do
        let(:permissions) { [:view_work_packages] }

        it_behaves_like "unauthorized access"
      end

      context "when the current user tries to watch the work package her- or himself" do
        let(:current_user) { available_watcher }
        let(:new_watcher) { available_watcher }

        it "responds with 201" do
          expect(subject.status).to eq(201)
        end
      end
    end
  end

  describe "#delete" do
    let(:deleted_watcher) { watching_user }
    let(:delete_path) { api_v3_paths.watcher deleted_watcher.id, work_package.id }

    before do
      perform_enqueued_jobs do
        delete delete_path
      end
    end

    context "for an authorized user" do
      let(:permissions) { %i[delete_work_package_watchers view_work_packages] }

      it "responds with 204" do
        expect(subject.status).to eq(204)
      end

      it "sends mails" do
        expect(ActionMailer::Base.deliveries.size)
          .to be 1

        expect(ActionMailer::Base.deliveries.map(&:to).flatten.uniq)
          .to match_array watching_user.mail

        expect(ActionMailer::Base.deliveries.first.text_part.body.encoded)
          .to include I18n.t("text_work_package_watcher_removed",
                             id: "##{work_package.id}",
                             watcher_changer: User.current)
      end

      context "when removing nonexistent user" do
        let(:delete_path) { api_v3_paths.watcher 9999, work_package.id }

        it_behaves_like "not found"
      end

      context "when removing user that is not watching" do
        let(:deleted_watcher) { available_watcher }

        it "responds with 204" do
          expect(subject.status).to eq(204)
        end
      end

      context "when work package doesn't exist" do
        let(:delete_path) { api_v3_paths.watcher watching_user.id, 9999 }

        it_behaves_like "not found",
                        I18n.t("api_v3.errors.not_found.work_package")
      end
    end

    context "for an unauthorized user" do
      context "when the current user tries to deassign another user from the watchers" do
        let(:permissions) { [:view_work_packages] }

        it_behaves_like "unauthorized access"
      end

      context "when the current user tries to unwatch the work package her- or himself" do
        let(:current_user) { watching_user }
        let(:deleted_watcher) { watching_user }

        it "responds with 204" do
          expect(subject.status).to eq(204)
        end
      end
    end
  end

  describe "#available_watchers" do
    let(:permissions) { %i[add_work_package_watchers view_work_packages] }
    let(:available_watchers_path) { api_v3_paths.available_watchers work_package.id }

    before do
      available_watcher
      get available_watchers_path
    end

    it_behaves_like "API V3 collection response", 2, 2, "User" do
      let(:elements) { [available_watcher, current_user] }
    end

    context "when signaling" do
      let(:select) { "total,count,elements/*" }

      let(:available_watchers_path) do
        "#{api_v3_paths.available_watchers(work_package.id)}?select=#{select}"
      end

      let(:expected) do
        {
          total: 2,
          count: 2,
          _embedded: {
            elements: [
              {
                _type: "User",
                id: available_watcher.id,
                name: available_watcher.name,
                _links: {
                  self: {
                    href: api_v3_paths.user(available_watcher.id),
                    title: available_watcher.name
                  }
                }
              },
              {
                _type: "User",
                id: current_user.id,
                name: current_user.name,
                firstname: current_user.firstname,
                lastname: current_user.lastname,
                _links: {
                  self: {
                    href: api_v3_paths.user(current_user.id),
                    title: current_user.name
                  }
                }
              }
            ]
          }
        }
      end

      it "is the reduced set of properties of the embedded elements" do
        expect(last_response.body)
          .to be_json_eql(expected.to_json)
      end
    end

    context "when the user does not have the necessary permissions" do
      let(:permissions) { [:view_work_packages] }

      it "responds with 403" do
        expect(subject.status).to be(403)
      end
    end

    describe "searching for a user" do
      let(:available_watchers_path) do
        path = api_v3_paths.available_watchers work_package.id
        filters = %([{ "name": { "operator": "~", "values": ["#{query}"] } }])

        "#{path}?filters=#{URI::RFC2396_Parser.new.escape(filters)}"
      end

      context "when that user does not exist" do
        let(:query) { "asdfasdfasdfasdf" }

        it_behaves_like "API V3 collection response", 0, 0, "User"
      end

      context "when that user does exist" do
        let(:query) { "strange" }

        it_behaves_like "API V3 collection response", 1, 1, "User"
      end
    end
  end
end
