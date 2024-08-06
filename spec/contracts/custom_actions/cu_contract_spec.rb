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
require "contracts/shared/model_contract_shared_context"

RSpec.describe CustomActions::CuContract do
  include_context "ModelContract shared context"

  let(:user) { build_stubbed(:user) }
  let(:action) do
    build_stubbed(:custom_action, actions:
                              [CustomActions::Actions::AssignedTo.new])
  end
  let(:contract) { described_class.new(action) }

  describe "name" do
    it "is writable" do
      action.name = "blubs"

      expect_contract_valid
    end

    it "needs to be set" do
      action.name = nil

      expect_contract_invalid
    end
  end

  describe "description" do
    it "is writable" do
      action.description = "blubs"

      expect_contract_valid
    end
  end

  describe "actions" do
    it "is writable" do
      responsible_action = CustomActions::Actions::Responsible.new

      action.actions = [responsible_action]

      expect_contract_valid
    end

    it "needs to have one" do
      action.actions = []

      expect_contract_invalid actions: :empty
    end

    it "requires a value if the action requires one" do
      action.actions = [CustomActions::Actions::Status.new([])]

      expect_contract_invalid actions: :empty
    end

    it "allows only the allowed values" do
      status_action = CustomActions::Actions::Status.new([0])
      allow(status_action)
        .to receive(:allowed_values)
        .and_return([{ value: nil, label: "-" },
                     { value: 1, label: "some status" }])

      action.actions = [status_action]

      expect_contract_invalid actions: :inclusion
    end

    it "is not allowed to have an inexistent action" do
      action.actions = [CustomActions::Actions::Inexistent.new]

      expect_contract_invalid actions: :does_not_exist
    end
  end

  describe "conditions" do
    it "is writable" do
      action.conditions = [double("some bogus condition", key: "some", values: "bogus", validate: true)]

      expect(contract.validate)
        .to be_truthy
    end

    it "allows only the allowed values" do
      status_condition = CustomActions::Conditions::Status.new([0])
      allow(status_condition)
        .to receive(:allowed_values)
        .and_return([{ value: nil, label: "-" },
                     { value: 1, label: "some status" }])

      action.conditions = [status_condition]

      expect_contract_invalid conditions: :inclusion
    end

    it "is not allowed to have an inexistent condition" do
      action.conditions = [CustomActions::Conditions::Inexistent.new]

      expect_contract_invalid conditions: :does_not_exist
    end
  end

  include_examples "contract reuses the model errors"
end
