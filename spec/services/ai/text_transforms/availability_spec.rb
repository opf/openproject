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

RSpec.describe AI::TextTransforms::Availability,
               with_flag: { ai_text_transform_actions: true },
               with_settings: { ai_text_transform_actions_enabled: true } do
  shared_let(:type) { create(:type) }
  shared_let(:other_type) { create(:type) }
  shared_let(:project) { create(:project, types: [type, other_type]) }
  shared_let(:work_package) { create(:work_package, project:, type:) }

  let(:gateway) { AI::TextTransforms::FakeGateway.new }
  let(:availability) { described_class.new(gateway:) }
  let(:context) { AI::TextTransforms::Context.for_work_package(work_package) }
  let(:action) { create(:ai_text_transform_action) }

  describe "#assistant" do
    it "is available when flag, setting and gateway agree" do
      expect(availability.assistant).to be_available
    end

    it "reports the feature flag", with_flag: { ai_text_transform_actions: false } do
      expect(availability.assistant.reason).to eq(:feature_disabled)
    end

    it "reports the setting", with_settings: { ai_text_transform_actions_enabled: false } do
      expect(availability.assistant.reason).to eq(:assistant_disabled)
    end

    it "reports the gateway" do
      availability = described_class.new(gateway: AI::TextTransforms::FakeGateway.new(ready: false))
      expect(availability.assistant.reason).to eq(:llm_unavailable)
    end
  end

  describe "#action" do
    it "accepts an active everywhere action without any context" do
      expect(availability.action(action, AI::TextTransforms::Context.none)).to be_available
    end

    it "rejects an inactive action" do
      action.update!(active: false)
      expect(availability.action(action, context).reason).to eq(:action_inactive)
    end

    it "requires a context for type-scoped actions" do
      action.update!(usage_scope: "all_work_package_types")
      expect(availability.action(action, AI::TextTransforms::Context.none).reason).to eq(:context_required)
      expect(availability.action(action, context)).to be_available
    end

    it "matches specific types" do
      action = create(:ai_text_transform_action, usage_scope: "specific_work_package_types", types: [other_type])
      expect(availability.action(action, context).reason).to eq(:type_mismatch)

      action.update!(types: [type])
      expect(availability.action(action, context)).to be_available
    end

    it "requires a template when the action injects it" do
      action.update!(usage_scope: "all_work_package_types", injects_type_template: true)
      expect(availability.action(action, context).reason).to eq(:template_missing)

      type.default_variant.update!(default_work_package_description: "## Steps")
      expect(availability.action(action, context)).to be_available
    end

    it "reports the assistant first" do
      availability = described_class.new(gateway: AI::TextTransforms::FakeGateway.new(ready: false))
      expect(availability.action(action, context).reason).to eq(:llm_unavailable)
    end
  end

  describe "#runnable" do
    it "accepts an active action regardless of context" do
      action.update!(usage_scope: "specific_work_package_types", types: [other_type])
      expect(availability.runnable(action)).to be_available
    end

    it "rejects an inactive action" do
      action.update!(active: false)
      expect(availability.runnable(action).reason).to eq(:action_inactive)
    end

    it "reports the assistant first", with_settings: { ai_text_transform_actions_enabled: false } do
      expect(availability.runnable(action).reason).to eq(:assistant_disabled)
    end
  end

  describe "#actions_for" do
    it "returns matching active actions ordered by position" do
      second = create(:ai_text_transform_action, position: 2)
      first = create(:ai_text_transform_action, position: 1)
      create(:ai_text_transform_action, active: false)
      create(:ai_text_transform_action, usage_scope: "specific_work_package_types", types: [other_type])

      expect(availability.actions_for(context)).to eq([first, second])
    end

    it "is empty when the assistant is unavailable", with_settings: { ai_text_transform_actions_enabled: false } do
      create(:ai_text_transform_action)
      expect(availability.actions_for(context)).to eq([])
    end
  end
end
