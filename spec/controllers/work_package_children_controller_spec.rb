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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackageChildrenController do
  shared_let(:user) { create(:admin) }
  shared_let(:task_type) { create(:type_task) }
  shared_let(:project) { create(:project, types: [task_type]) }
  shared_let(:work_package) { create(:work_package, subject: "work_package", project:, type: task_type) }
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }

  current_user { user }

  describe "GET /work_packages/:work_package_id/children/new" do
    it "renders a creation dialog that submits back to the relations tab" do
      get("new", params: { work_package_id: work_package.id }, as: :turbo_stream)

      expect(response).to be_successful
      expect(response.body).to include("/work_packages/#{work_package.id}/children")
    end

    context "when the user may manage subtasks but not add work packages" do
      current_user do
        create(:user, member_with_permissions: { project => %i[view_work_packages manage_subtasks] })
      end

      it "refuses to open the dialog" do
        get("new", params: { work_package_id: work_package.id }, as: :turbo_stream)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /work_packages/:work_package_id/children" do
    before do
      allow(WorkPackageRelationsTab::IndexComponent).to receive(:new).and_call_original
      allow(controller).to receive(:render_success_flash_message_via_turbo_stream).and_call_original
    end

    it "creates the work package as a child and scrolls the relations tab to it" do
      post("create",
           params: { work_package_id: work_package.id,
                     work_package: { subject: "New child", type_id: task_type.id } },
           as: :turbo_stream)

      expect(response).to have_http_status(:ok)

      new_child = WorkPackage.order(:id).last
      expect(new_child.subject).to eq("New child")
      expect(new_child.parent).to eq(work_package)

      expect(WorkPackageRelationsTab::IndexComponent)
        .to have_received(:new)
        .with(work_package:, relation_to_scroll_to: new_child)
    end

    it "keeps the dialog open on its errors when the work package is invalid" do
      post("create",
           params: { work_package_id: work_package.id,
                     work_package: { subject: "", type_id: task_type.id } },
           as: :turbo_stream)

      # A non-success status is what keeps the Primer dialog from closing, see turbo-event-listeners.ts
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Subject can&#39;t be blank")
    end

    it "confirms that the work package was created as a child" do
      post("create",
           params: { work_package_id: work_package.id,
                     work_package: { subject: "New child", type_id: task_type.id } },
           as: :turbo_stream)

      expect(controller)
        .to have_received(:render_success_flash_message_via_turbo_stream)
        .with(message: "New work package created and added as a child")
    end
  end

  describe "POST /work_packages/:work_package_id/children/refresh_form" do
    it "keeps the refreshed form submitting back to the relations tab" do
      post("refresh_form",
           params: { work_package_id: work_package.id,
                     work_package: { subject: "New child", type_id: task_type.id } },
           as: :turbo_stream)

      expect(response).to be_successful
      expect(response.body).to include("/work_packages/#{work_package.id}/children")
    end
  end
end
