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

RSpec.describe AI::TextTransforms::CreateRun,
               with_flag: { ai_text_transform_actions: true },
               with_settings: { ai_text_transform_actions_enabled: true } do
  shared_let(:user) { create(:user) }
  shared_let(:action) { create(:ai_text_transform_action, prompt: "Fix grammar only.") }

  let(:gateway) { AI::TextTransforms::FakeGateway.new }
  let(:availability) { AI::TextTransforms::Availability.new(gateway:) }
  let(:context) { AI::TextTransforms::Context.none }
  let(:content) { "Login page dont work." }

  subject(:call) { described_class.new(user:, action:, context:, content:, availability:).call }

  it "stores the assembled prompt and enqueues the job with the run id" do
    expect { call }.to have_enqueued_job(AI::TextTransformJob)

    expect(AI::TextTransformJob).to have_been_enqueued.with(call.result.id)
    expect(call).to be_success
    expect(call.result).to be_persisted.and be_queued
    expect(call.result).to have_attributes(
      user:,
      action:,
      input: content,
      system_prompt: AI::TextTransforms::Prompt.build(action:, context:, content:).system
    )
  end

  context "when the action is not available" do
    before { action.update!(active: false) }

    it "creates nothing and carries the reason" do
      expect { call }.not_to have_enqueued_job(AI::TextTransformJob)

      expect(call).to be_failure
      expect(AI::TextTransformRun.count).to eq(0)
      expect(call.errors.details[:base]).to eq([{ error: :not_available, reason: :action_inactive }])
      expect(call.errors.full_messages).to eq(["This action is not available."])
    end
  end

  context "when the action is nil" do
    let(:action) { nil }

    it "fails with unknown_action" do
      expect { call }.not_to have_enqueued_job(AI::TextTransformJob)

      expect(call).to be_failure
      expect(AI::TextTransformRun.count).to eq(0)
      expect(call.errors.details[:base]).to eq([{ error: :not_available, reason: :unknown_action }])
    end
  end

  context "when the content is blank" do
    let(:content) { "" }

    it "returns the model errors and enqueues nothing" do
      expect { call }.not_to have_enqueued_job(AI::TextTransformJob)

      expect(call).to be_failure
      expect(AI::TextTransformRun.count).to eq(0)
      expect(call.errors.symbols_for(:input)).to include(:blank)
      expect(call.errors.details[:base]).to be_empty
    end
  end
end
