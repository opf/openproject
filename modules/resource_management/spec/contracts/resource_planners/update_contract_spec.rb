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
require_relative "shared_contract_examples"

RSpec.describe ResourcePlanners::UpdateContract do
  include_context "ModelContract shared context"

  it_behaves_like "resource planner contract" do
    let(:contract) { described_class.new(resource_planner, current_user) }
  end

  describe "writable attributes" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners] })
    end
    let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
    let(:resource_planner) { build_stubbed(:resource_planner, project:, principal: current_user) }
    let(:contract) { described_class.new(resource_planner, current_user) }

    it "does not allow project to be set" do
      expect(contract.writable?(:project)).to be(false)
    end

    it "does not allow principal to be set" do
      expect(contract.writable?(:principal)).to be(false)
    end

    it "allows public to be set" do
      expect(contract.writable?(:public)).to be(true)
    end
  end

  describe "changing the public flag" do
    let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
    let(:contract) { described_class.new(resource_planner, current_user) }
    let(:unauthorized_message) { I18n.t("activerecord.errors.messages.error_unauthorized") }

    context "when the user lacks manage_public_resource_planners" do
      let(:current_user) do
        create(:user, member_with_permissions: { project => %i[view_resource_planners] })
      end

      context "and the planner is public" do
        let(:resource_planner) do
          create(:resource_planner, project:, principal: current_user, public: true)
        end

        # Regression: unsetting public bypassed the permission check because the
        # validation only ran when the *resulting* state was public.
        it "cannot unset the public flag" do
          resource_planner.public = false
          contract.validate

          expect(contract.errors[:public]).to include(unauthorized_message)
        end
      end

      context "and the planner is private" do
        let(:resource_planner) do
          create(:resource_planner, project:, principal: current_user, public: false)
        end

        it "cannot set the public flag" do
          resource_planner.public = true
          contract.validate

          expect(contract.errors[:public]).to include(unauthorized_message)
        end

        it "is valid when the public flag is left unchanged" do
          contract.validate

          expect(contract.errors[:public]).to be_empty
        end
      end
    end

    context "when the user can manage_public_resource_planners" do
      let(:current_user) do
        create(:user,
               member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
      end
      let(:resource_planner) do
        create(:resource_planner, project:, principal: current_user, public: true)
      end

      it "can unset the public flag" do
        resource_planner.public = false
        contract.validate

        expect(contract.errors[:public]).to be_empty
      end
    end
  end
end
