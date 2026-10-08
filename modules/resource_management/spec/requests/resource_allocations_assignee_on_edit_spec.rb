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

RSpec.describe "Editing the assignee of a resource allocation",
               :skip_csrf, type: :rails_request, with_ee: %i[resource_management] do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_resource_planners allocate_user_resources view_work_packages] })
  end
  shared_let(:assignee) do
    create(:user, firstname: "Dev", lastname: "One", member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:other_member) do
    create(:user, firstname: "Dev", lastname: "Two", member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:non_candidate) do
    create(:user, firstname: "Ops", lastname: "Three", member_with_permissions: { project => %i[view_work_packages] })
  end
  shared_let(:deleted_user) { create(:deleted_user) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:placeholder) do
    filters = UserQuery.new.tap { |query| query.where("name", "~", ["dev"]) }.filters
    create(:placeholder_user, name: "Senior Developer", user_filter: filters)
  end

  before { login_as user }

  def edit_dialog
    get edit_project_resource_allocation_path(project, allocation), as: :turbo_stream
    response
  end

  def update(placeholder_or_user_id:, allocated_hours: "16h")
    patch project_resource_allocation_path(project, allocation),
          params: { resource_allocation: {
            placeholder_or_user_id:,
            entity_type: "WorkPackage",
            entity_id: work_package.id,
            date_range: "2026-01-05 - 2026-01-09",
            allocated_hours:
          } },
          as: :turbo_stream
    response
  end

  def refresh_form(placeholder_or_user_id:)
    post refresh_form_project_resource_allocation_path(project, allocation),
         params: { resource_allocation: {
           placeholder_or_user_id:,
           entity_type: "WorkPackage",
           entity_id: work_package.id,
           date_range: "2026-01-05 - 2026-01-09",
           allocated_hours: "16h"
         } },
         as: :turbo_stream
    response
  end

  def expect_staffed_from_caption
    expect(response.body).to have_turbo_stream(action: "dialog") do
      assert_select "[data-test-selector='op-resource-allocation-staffed-from']", text: /#{placeholder.name}/
    end
  end

  def expect_deleted_assignee_notice
    expect(response.body).to have_turbo_stream(action: "dialog") do
      assert_select "[data-test-selector='op-resource-allocation-assignee-deleted']"
    end
  end

  def principals_offered_by_picker
    picker = Nokogiri::HTML(edit_dialog.body).at_css("opce-resource-allocation-autocompleter")
    filters = JSON.parse(picker["data-filters"]).map do |filter|
      { filter["name"] => { operator: filter["operator"], values: filter["values"] } }
    end

    get "/api/v3/allocatable_principals", params: { filters: filters.to_json, pageSize: 100 }
    # parsed_body does not know the application/hal+json content type of API v3.
    JSON.parse(response.body).dig("_embedded", "elements").pluck("id") # rubocop:disable Rails/ResponseParsedBody
  end

  context "for a staffed allocation" do
    let!(:allocation) do
      create(:resource_allocation, entity: work_package, placeholder_user: placeholder, principal: assignee,
                                   principal_assigned_by: other_member, allocated_time: 600)
    end

    it "pre-fills the picker with the assigned user and names the placeholder it was staffed from" do
      expect(edit_dialog).to have_http_status(:ok)
      expect(response.body).to include(%(data-input-value="#{assignee.id}"))
      expect_staffed_from_caption
    end

    it "offers only the users matching the placeholder's criteria in the picker" do
      expect(principals_offered_by_picker).to contain_exactly(assignee.id, other_member.id)
    end

    it "keeps naming the placeholder when the form refreshes" do
      expect(refresh_form(placeholder_or_user_id: assignee.id)).to have_http_status(:ok)
      expect(response).to have_turbo_stream(
        action: "replace",
        target: ResourceAllocations::AllocationStep::ResourceFilterComponent.wrapper_key
      ) do
        assert_select "[data-test-selector='op-resource-allocation-staffed-from']", text: /#{placeholder.name}/
      end
    end

    it "keeps the assigned user and the placeholder when only the hours change" do
      expect(update(placeholder_or_user_id: assignee.id)).to have_http_status(:ok)

      allocation.reload
      expect(allocation.allocated_time).to eq(16 * 60)
      expect(allocation.principal).to eq(assignee)
      expect(allocation.placeholder_user).to eq(placeholder)
      expect(allocation.principal_assigned_by).to eq(other_member)
    end

    it "re-staffs the allocation when a different user is picked" do
      expect(update(placeholder_or_user_id: other_member.id)).to have_http_status(:ok)

      allocation.reload
      expect(allocation.principal).to eq(other_member)
      expect(allocation.placeholder_user).to eq(placeholder)
      expect(allocation.principal_assigned_by).to eq(user)
    end
  end

  context "for an allocation of a placeholder that has not been staffed yet" do
    shared_let(:other_placeholder) do
      filters = UserQuery.new.tap { |query| query.where("name", "~", ["ops"]) }.filters
      create(:placeholder_user, name: "Site Reliability Engineer", user_filter: filters)
    end

    let!(:allocation) do
      create(:resource_allocation, entity: work_package, placeholder_user: placeholder, principal: nil,
                                   allocated_time: 600)
    end

    it "offers other placeholders in the picker" do
      expect(principals_offered_by_picker).to include(other_placeholder.id)
    end

    it "switches to the newly picked placeholder" do
      expect(update(placeholder_or_user_id: other_placeholder.id)).to have_http_status(:ok)

      allocation.reload
      expect(allocation.placeholder_user).to eq(other_placeholder)
      expect(allocation.principal).to be_nil
    end

    it "becomes an allocation of the picked user, dropping the placeholder" do
      expect(update(placeholder_or_user_id: assignee.id)).to have_http_status(:ok)

      allocation.reload
      expect(allocation.principal).to eq(assignee)
      expect(allocation.placeholder_user).to be_nil
    end
  end

  context "for a staffed allocation whose assigned user was deleted" do
    let!(:allocation) do
      create(:resource_allocation, entity: work_package, placeholder_user: placeholder, principal: deleted_user,
                                   principal_assigned_by: other_member, allocated_time: 600)
    end

    it "pre-fills the picker with the deleted user, names the placeholder and explains the deletion" do
      expect(edit_dialog).to have_http_status(:ok)
      expect(response.body).to include(%(data-input-value="#{deleted_user.id}"))
      expect_staffed_from_caption
      expect_deleted_assignee_notice
    end

    it "keeps the deleted user and the placeholder when only the hours change" do
      expect(update(placeholder_or_user_id: deleted_user.id)).to have_http_status(:ok)

      allocation.reload
      expect(allocation.allocated_time).to eq(16 * 60)
      expect(allocation.principal).to eq(deleted_user)
      expect(allocation.placeholder_user).to eq(placeholder)
    end

    it "re-staffs the allocation when a different user is picked" do
      expect(update(placeholder_or_user_id: other_member.id)).to have_http_status(:ok)

      allocation.reload
      expect(allocation.principal).to eq(other_member)
      expect(allocation.placeholder_user).to eq(placeholder)
      expect(allocation.principal_assigned_by).to eq(user)
    end
  end

  context "for an allocation assigned directly to a user who was deleted" do
    let!(:allocation) do
      create(:resource_allocation, entity: work_package, principal: deleted_user, allocated_time: 600)
    end

    def deleted_assignee_banner_stream(&)
      expect(response).to have_turbo_stream(
        action: "replace",
        target: ResourceAllocations::AllocationStep::DeletedAssigneeBannerComponent.wrapper_key,
        &
      )
    end

    it "keeps explaining the deletion when the form refreshes with the deleted user" do
      expect(refresh_form(placeholder_or_user_id: deleted_user.id)).to have_http_status(:ok)
      deleted_assignee_banner_stream do
        assert_select "[data-test-selector='op-resource-allocation-assignee-deleted']"
      end
    end

    it "drops the explanation when the form refreshes with someone else picked" do
      expect(refresh_form(placeholder_or_user_id: other_member.id)).to have_http_status(:ok)
      deleted_assignee_banner_stream do
        assert_select "[data-test-selector='op-resource-allocation-assignee-deleted']", count: 0
      end
    end

    shared_examples "an editable allocation of a deleted user" do
      it "pre-fills the picker with the deleted user and explains the deletion" do
        expect(edit_dialog).to have_http_status(:ok)
        expect(response.body).to include(%(data-input-value="#{deleted_user.id}"))
        expect_deleted_assignee_notice
      end

      it "keeps the deleted user when only the hours change" do
        expect(update(placeholder_or_user_id: deleted_user.id)).to have_http_status(:ok)

        allocation.reload
        expect(allocation.allocated_time).to eq(16 * 60)
        expect(allocation.principal).to eq(deleted_user)
      end
    end

    context "as a user who cannot see the deleted user" do
      it_behaves_like "an editable allocation of a deleted user"
    end

    context "as an administrator" do
      before { login_as create(:admin) }

      it_behaves_like "an editable allocation of a deleted user"
    end
  end
end
