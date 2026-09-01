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

RSpec.describe "Work package moves", :webmock, type: :rails_request do
  shared_let(:user) { create(:admin) }
  shared_let(:type) { create(:type) }
  shared_let(:source) { create(:project, name: "Source", types: [type]) }
  shared_let(:target) { create(:project, name: "Target", types: [type]) }
  shared_let(:work_package) { create(:work_package, project: source, type:) }

  before { login_as(user) }

  describe "POST refresh_form" do
    def expect_turbo_streamed_move_form
      expect(response).to have_turbo_stream(
        action: "update",
        target: WorkPackages::Moves::FormComponent.wrapper_key
      )
    end

    # Fetches the CSRF token from the move form page, mirroring how the
    # refresh controller reads it from the meta tag in production.
    def current_csrf_token
      get new_move_work_packages_path("ids[]" => work_package.id)
      response.parsed_body.at_css("meta[name='csrf-token']")["content"]
    end

    let(:params) { { "ids[]" => work_package.id, new_project_id: target.id, notes: "secret note" } }

    subject(:request) do
      post refresh_form_move_work_packages_path,
           params:,
           headers: { "X-CSRF-Token" => current_csrf_token },
           as: :turbo_stream
    end

    it "renders the refreshed form as a turbo stream without exposing data in the URL" do
      request

      expect(response).to have_http_status(:ok)
      expect_turbo_streamed_move_form
      expect(response.body).to include("secret note")
    end

    context "with malformed custom field values" do
      let(:params) do
        {
          "ids[]" => work_package.id,
          new_project_id: target.id,
          custom_field_values: ["Malformed"]
        }
      end

      it "ignores them and renders the refreshed form" do
        request

        expect(response).to have_http_status(:ok)
        expect_turbo_streamed_move_form
      end
    end

    context "with current move form values" do
      let(:version) { create(:version, project: target) }
      let(:observed_in_version) { create(:version, project: target, name: "Observed version") }
      let(:priority) { create(:priority, name: "High") }
      let(:assignee_role) { create(:project_role, permissions: %i[view_work_packages work_package_assigned]) }
      let(:assignee) { create(:user, member_with_roles: { target => assignee_role }) }
      let(:status) { create(:status) }
      let(:custom_field) do
        create(:string_wp_custom_field, is_required: true, types: [type], projects: [source, target])
      end

      let(:params) do
        {
          "ids[]" => work_package.id,
          new_project_id: target.id,
          new_type_id: type.id,
          status_id: status.id,
          "target_version_ids[]": version.id,
          "observed_in_version_ids[]": observed_in_version.id,
          priority_id: priority.id,
          assigned_to_id: assignee.id,
          responsible_id: "none",
          start_date: "2026-07-01",
          due_date: "2026-07-15",
          custom_field_values: { custom_field.id => "Keep me" }
        }
      end

      before do
        create(:workflow, type:, old_status: work_package.status, new_status: status, role: assignee_role)
      end

      it "preserves them in the refreshed form" do
        request

        expect(response).to have_http_status(:ok)
        expect_turbo_streamed_move_form
        expect(response.body)
          .to include(%(option selected="selected" value="#{status.id}"))
          .and include(%(option selected="selected" value="#{version.id}"))
          .and include(%(option selected="selected" value="#{observed_in_version.id}"))
          .and include(%(option selected="selected" value="#{priority.id}"))
          .and include(%(option selected="selected" value="#{assignee.id}"))
          .and include(%(option selected="selected" value="none"))
          .and include(%(data-value="&quot;2026-07-01&quot;"))
          .and include(%(data-value="&quot;2026-07-15&quot;"))
          .and match(/name="custom_field_values\[#{custom_field.id}\]"[^>]+value="Keep me"/)
      end
    end
  end
end
