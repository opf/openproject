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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
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

  describe "GET new" do
    let!(:child) { create(:work_package, project: source, parent: work_package, type:) }

    def visit_new_move_page(**params)
      get new_move_work_packages_path(ids: [work_package.id], **params)
    end

    it "shows the descendant count when descendants are included by default" do
      visit_new_move_page

      expect(response.body).to include(I18n.t("work_packages.x_descendants", count: 1))
    end

    it "hides the descendant count when 'move just this work package' was chosen" do
      visit_new_move_page(move_descendants: "false")

      expect(response.body).not_to include(I18n.t("work_packages.x_descendants", count: 1))
    end

    it "still shows the descendant count when copying, regardless of move_descendants" do
      visit_new_move_page(copy: "", move_descendants: "false")

      expect(response.body).to include(I18n.t("work_packages.x_descendants", count: 1))
    end

    context "when the child is in a project invisible to the user" do
      let(:mover_role) { create(:project_role, permissions: %i[view_work_packages move_work_packages]) }
      let(:mover) { create(:user, member_with_roles: { source => mover_role }) }
      let(:other_project) { create(:project, types: [type]) }
      let!(:child) { create(:work_package, project: other_project, parent: work_package, type:) }

      before { login_as(mover) }

      it "does not count it, since it will not actually move along" do
        visit_new_move_page

        expect(response.body).not_to include(I18n.t("work_packages.x_descendants", count: 1))
      end
    end
  end

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

    context "when copying with the copy_work_packages but not the move_work_packages permission" do
      let(:copy_role) { create(:project_role, permissions: %i[view_work_packages copy_work_packages add_work_packages]) }
      let(:user) { create(:user, member_with_roles: { source => copy_role, target => copy_role }) }
      let(:params) { { "ids[]" => work_package.id, copy: "", new_project_id: target.id } }

      it "keeps the selected target project" do
        request

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(%(data-model="{&quot;id&quot;:#{target.id},))
      end
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
        create(:string_wp_custom_field, is_required: true, types: [type])
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

  describe "GET move_dialog" do
    def open_dialog(ids:, **params)
      get move_dialog_work_packages_path(ids:, **params), as: :turbo_stream
    end

    context "when the work package has no descendants" do
      it "skips the dialog and redirects straight to the move form via a turbo-stream redirect" do
        open_dialog(ids: [work_package.id])

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include('action="redirect_to"')
        expect(response.body).to include("ids%5B%5D=#{work_package.id}")
      end
    end

    context "when the work package has a descendant" do
      let!(:child) { create(:work_package, project: source, parent: work_package, type:) }

      it "renders the move dialog with the descendants choice and permission banner" do
        open_dialog(ids: [work_package.id])

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("work_packages.move_dialog.descendants_choice.self_only_label"))
        expect(response.body).to include(I18n.t("work_packages.move_dialog_shared.descendants_choice.with_descendants_label"))
        expect(response.body).to include(I18n.t("work_packages.move_dialog_shared.permission_banner"))
      end
    end

    context "when the work package's only descendant is invisible to the user" do
      let(:mover_role) { create(:project_role, permissions: %i[view_work_packages move_work_packages]) }
      let(:mover) { create(:user, member_with_roles: { source => mover_role }) }
      let(:other_project) { create(:project, types: [type]) }
      let!(:child) { create(:work_package, project: other_project, parent: work_package, type:) }

      before { login_as(mover) }

      it "skips the dialog, since there is nothing the user could choose to include" do
        open_dialog(ids: [work_package.id])

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include('action="redirect_to"')
      end
    end

    context "when the work package has a descendant and cross-project relations are disabled",
            with_settings: { cross_project_work_package_relations: false } do
      let!(:child) { create(:work_package, project: source, parent: work_package, type:) }
      let(:dialog) { Capybara.string(response.body) }

      it "shows the same dialog with 'move just this work package' disabled and the info banner" do
        open_dialog(ids: [work_package.id])

        expect(response).to have_http_status(:ok)
        expect(dialog).to have_text(I18n.t("work_packages.move_dialog.descendants_choice.heading"))
        expect(dialog).to have_css("input[type='radio'][value='false'][disabled]")
        expect(dialog).to have_checked_field(
          I18n.t("work_packages.move_dialog_shared.descendants_choice.with_descendants_label"), visible: :all
        )
        expect(dialog).to have_text(I18n.t("work_packages.move_dialog_shared.same_project_required_notice"))
        expect(dialog).to have_no_text(I18n.t("work_packages.move_dialog_shared.permission_banner"))
      end
    end

    context "with more than one work package, one of them having a descendant" do
      let!(:other_work_package) { create(:work_package, project: source, type:) }
      let!(:child) { create(:work_package, project: source, parent: work_package, type:) }

      it "renders the bulk move dialog" do
        open_dialog(ids: [work_package.id, other_work_package.id])

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("work_packages.bulk_move_dialog.descendants_choice.self_only_label"))
      end
    end

    context "when the user lacks move_work_packages on the work package's project" do
      let(:unauthorized_role) { create(:project_role, permissions: %i[view_work_packages]) }
      let(:unauthorized_user) { create(:user, member_with_roles: { source => unauthorized_role }) }

      before { login_as(unauthorized_user) }

      it "is forbidden" do
        open_dialog(ids: [work_package.id])

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST confirm_move", :skip_csrf do
    it "redirects to the move form, carrying the descendants choice forward" do
      post confirm_move_work_packages_path(ids: [work_package.id], move_descendants: "true")

      expect(response).to redirect_to(new_move_work_packages_path(ids: [work_package.id], move_descendants: "true"))
    end

    it "redirects without a descendants choice when none was submitted" do
      post confirm_move_work_packages_path(ids: [work_package.id])

      expect(response).to redirect_to(new_move_work_packages_path(ids: [work_package.id]))
    end
  end
end
