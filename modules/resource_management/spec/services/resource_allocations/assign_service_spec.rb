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

RSpec.describe ResourceAllocations::AssignService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:assigner) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners assign_users_to_generic_allocations] })
  end
  shared_let(:work_package) { create(:work_package, project:) }

  # A generic allocation whose filter matches developers speaking German/English.
  shared_let(:allocation) { create(:resource_allocation, :with_user_filter, entity: work_package) }

  # A user the filter selects (developer, speaks German), member of the project.
  let(:matching_user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages] }).tap do |user|
      job_title = UserCustomField.find_by(name: "Job title")
      language = UserCustomField.find_by(name: "Spoken language")
      user.custom_field_values = {
        job_title.id => job_title.custom_options.find_by(value: "Developer").id,
        language.id => [language.custom_options.find_by(value: "German").id]
      }
      user.save!
    end
  end

  subject(:service_call) do
    described_class.new(user: assigner, model: allocation).call(principal: matching_user, principal_assigned_by: assigner)
  end

  it "assigns the user and records who assigned them" do
    result = service_call
    expect(result).to be_success, "expected success but got: #{result.errors.full_messages}"
    expect(allocation.reload.principal).to eq(matching_user)
    expect(allocation.principal_assigned_by).to eq(assigner)
  end

  it "keeps the allocation generic: the requested resource is untouched" do
    expect { service_call }.not_to change { allocation.reload.user_resource_id }
    expect(allocation.user_resource.user_filter).to be_present
    expect(allocation).to be_filter_based
  end

  context "when the selected user does not match the filter" do
    let(:non_matching_user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

    subject(:service_call) do
      described_class.new(user: assigner, model: allocation).call(principal: non_matching_user)
    end

    it "fails validation and does not assign" do
      expect(service_call).not_to be_success
      expect(allocation.reload.principal).to be_nil
    end
  end

  context "when the user lacks the assign permission" do
    let(:unauthorized) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

    subject(:service_call) do
      described_class.new(user: unauthorized, model: allocation).call(principal: matching_user)
    end

    it "fails with an authorization error" do
      expect(service_call).not_to be_success
      expect(service_call.errors[:base]).to include(I18n.t("activerecord.errors.messages.error_unauthorized"))
    end
  end
end
