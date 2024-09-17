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

require "spec_helper"
require "rack/test"

RSpec.describe API::V3::WorkPackages::WorkPackagesByProjectAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:project) { create(:project_with_types, public: false) }
  let(:role) { create(:project_role, permissions:) }
  let(:path) { api_v3_paths.work_packages_by_project project.id }
  let(:permissions) { %i[add_work_packages view_project] }
  let(:status) { build(:status, is_default: true) }
  let(:priority) { build(:priority, is_default: true) }
  let(:other_user) { nil }
  let(:parameters) do
    {
      subject: "new work packages",
      _links: {
        type: {
          href: api_v3_paths.type(project.types.first.id)
        }
      }
    }
  end

  current_user do
    create(:user, member_with_roles: { project => role })
  end

  before do
    status.save!
    priority.save!
    other_user

    perform_enqueued_jobs do
      post path, parameters.to_json
    end
  end

  describe "notifications" do
    let(:other_user) do
      create(:user,
             member_with_permissions: { project => %i(view_work_packages) },
             notification_settings: [
               build(:notification_setting,
                     work_package_created: true)
             ])
    end

    it "creates a notification" do
      expect(Notification.where(recipient: other_user, resource: WorkPackage.last))
        .to exist
    end

    context "without notifications" do
      let(:path) { "#{api_v3_paths.work_packages_by_project(project.id)}?notify=false" }

      it "creates no notification" do
        expect(Notification)
          .not_to exist
      end
    end

    context "with notifications" do
      let(:path) { "#{api_v3_paths.work_packages_by_project(project.id)}?notify=true" }

      it "creates a notification" do
        expect(Notification.where(recipient: other_user, resource: WorkPackage.last))
          .to exist
      end
    end
  end

  it "returns Created(201)" do
    expect(last_response).to have_http_status(:created)
  end

  it "creates a work package" do
    expect(WorkPackage.all.count).to eq(1)
  end

  it "uses the given parameters" do
    expect(WorkPackage.first.subject).to eq(parameters[:subject])
  end

  context "without permissions" do
    let(:current_user) { create(:user) }

    it "hides the endpoint" do
      expect(last_response).to have_http_status(:not_found)
    end
  end

  context "with view_project permission" do
    # Note that this just removes the add_work_packages permission
    # view_project is actually provided by being a member of the project
    let(:permissions) { [:view_project] }

    it "points out the missing permission" do
      expect(last_response).to have_http_status(:forbidden)
    end
  end

  context "with empty parameters" do
    let(:parameters) { {} }

    it_behaves_like "constraint violation" do
      let(:message) { "Subject can't be blank" }
    end

    it "does not create a work package" do
      expect(WorkPackage.all.count).to eq(0)
    end
  end

  context "with bogus parameters" do
    let(:parameters) do
      {
        bogus: "bogus",
        _links: {
          type: {
            href: api_v3_paths.type(project.types.first.id)
          }
        }
      }
    end

    it_behaves_like "constraint violation" do
      let(:message) { "Subject can't be blank" }
    end

    it "does not create a work package" do
      expect(WorkPackage.all.count).to eq(0)
    end
  end

  context "with an invalid value" do
    let(:parameters) do
      {
        subject: nil,
        _links: {
          type: {
            href: api_v3_paths.type(project.types.first.id)
          }
        }
      }
    end

    it_behaves_like "constraint violation" do
      let(:message) { "Subject can't be blank" }
    end

    it "does not create a work package" do
      expect(WorkPackage.all.count).to eq(0)
    end
  end
end
