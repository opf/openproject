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

RSpec.describe ResourcePlanners::TogglePublicService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }

  let!(:resource_planner) { create(:resource_planner, project:, principal: user, public: initial_public) }
  let(:initial_public) { false }

  subject(:service_call) { described_class.new(user:, model: resource_planner).call }

  context "when user has manage_public_resource_planners" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
    end

    it "flips a private planner to public" do
      expect(service_call).to be_success
      expect(resource_planner.reload).to be_public
    end

    context "when the planner is already public" do
      let(:initial_public) { true }

      it "flips it back to private" do
        expect(service_call).to be_success
        expect(resource_planner.reload).not_to be_public
      end
    end
  end

  context "when user lacks the manage permission" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners] })
    end

    it "fails with an authorization error" do
      expect(service_call).not_to be_success
      expect(resource_planner.reload).not_to be_public
      expect(service_call.errors[:base]).to include(I18n.t("activerecord.errors.messages.error_unauthorized"))
    end
  end

  context "when user has no permissions at all" do
    let(:user) { create(:user) }

    it "fails" do
      expect(service_call).not_to be_success
      expect(resource_planner.reload).not_to be_public
    end
  end
end
