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

RSpec.describe ResourcePlanners::CreateService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end

  let(:default_view_class_name) { "ResourcePlannerCalendarView" }
  let(:params) do
    { name: "My planner", project:, default_view_class_name: }
  end

  before do
    allow(ResourcePlanner).to receive(:allowed_children).and_return(%w[ResourcePlannerCalendarView])
  end

  subject(:service_call) { described_class.new(user:).call(params) }

  it "creates a resource planner" do
    result = service_call
    expect(result).to be_success, "expected success but got errors: #{result.errors.full_messages}"
    expect(result.result.name).to eq("My planner")
    expect(result.result.principal).to eq(user)
    expect(result.result.project).to eq(project)
  end

  it "ignores any caller-supplied principal and assigns the calling user" do
    other = create(:user)
    result = described_class.new(user:).call(params.merge(principal: other))
    expect(result.result.principal).to eq(user)
  end

  context "when favorite: true is passed" do
    it "marks the new planner as favorited by the calling user" do
      result = described_class.new(user:).call(params.merge(favorite: true))
      expect(result).to be_success
      expect(result.result.favorited_by?(user)).to be(true)
    end
  end

  context "when favorite is not passed" do
    it "does not favorite the planner" do
      result = service_call
      expect(result.result.favorited_by?(user)).to be(false)
    end
  end

  context "when default_view_class_name is not in allowed_children" do
    let(:default_view_class_name) { "UnknownView" }

    it "fails without persisting the planner" do
      expect { service_call }.not_to change(ResourcePlanner, :count)
      expect(service_call).not_to be_success
      expect(service_call.errors.symbols_for(:default_view_class_name)).to include(:inclusion)
    end
  end

  context "when allowed_children is empty" do
    before do
      allow(ResourcePlanner).to receive(:allowed_children).and_return([])
    end

    it "fails" do
      expect(service_call).not_to be_success
      expect(service_call.errors.symbols_for(:default_view_class_name)).to include(:inclusion)
    end
  end

  context "when user lacks permissions" do
    let(:user) { create(:user) }

    it "fails with an authorization error" do
      expect(service_call).not_to be_success
      expect(service_call.errors[:base]).to include(I18n.t("activerecord.errors.messages.error_unauthorized"))
    end
  end
end
