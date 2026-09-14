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

RSpec.describe AI::TextTransformAction do
  subject(:action) { build(:ai_text_transform_action) }

  it { is_expected.to validate_presence_of(:label) }
  it { is_expected.to validate_length_of(:label).is_at_most(255) }
  it { is_expected.to validate_presence_of(:prompt) }

  describe "usage_scope" do
    it "defaults to everywhere" do
      expect(described_class.new.usage_scope).to eq("everywhere")
    end

    it "allows only the defined values" do
      expect(described_class.usage_scopes.keys)
        .to contain_exactly("everywhere", "all_work_package_types", "specific_work_package_types")
    end

    it "adds a validation error for unknown values" do
      action.usage_scope = "somewhere"

      expect(action).not_to be_valid
      expect(action.errors[:usage_scope]).to be_present
    end
  end

  describe "types" do
    it "are not required for the everywhere and all_work_package_types scopes" do
      expect(build(:ai_text_transform_action, usage_scope: "everywhere")).to be_valid
      expect(build(:ai_text_transform_action, usage_scope: "all_work_package_types")).to be_valid
    end

    it "are required for the specific_work_package_types scope" do
      action = build(:ai_text_transform_action, usage_scope: "specific_work_package_types")

      expect(action).not_to be_valid
      expect(action.errors[:types]).to be_present
    end

    it "make the specific_work_package_types scope valid when assigned" do
      expect(build(:ai_text_transform_action, :for_specific_types)).to be_valid
    end

    it "cannot contain the same type twice" do
      action = create(:ai_text_transform_action, :for_specific_types)
      duplicate = AI::TextTransformActionType.new(text_transform_action: action, type: action.types.first)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:type_id]).to be_present
    end

    it "lose their assignment when the type is destroyed" do
      action = create(:ai_text_transform_action, :for_specific_types)

      action.types.first.destroy!

      expect(action.reload.types).to be_empty
      expect(AI::TextTransformActionType.count).to eq(0)
    end
  end

  describe "injects_type_template" do
    it "is allowed for the work package type scopes" do
      expect(build(:ai_text_transform_action, usage_scope: "all_work_package_types", injects_type_template: true))
        .to be_valid
    end

    it "must be absent for the everywhere scope" do
      action = build(:ai_text_transform_action, usage_scope: "everywhere", injects_type_template: true)

      expect(action).not_to be_valid
      expect(action.errors[:injects_type_template]).to be_present
    end
  end

  describe ".ordered" do
    it "sorts by position" do
      second = create(:ai_text_transform_action, position: 2)
      first = create(:ai_text_transform_action, position: 1)

      expect(described_class.ordered).to eq([first, second])
    end
  end

  describe ".active" do
    it "returns only active actions" do
      active = create(:ai_text_transform_action)
      create(:ai_text_transform_action, active: false)

      expect(described_class.active).to contain_exactly(active)
    end
  end
end
