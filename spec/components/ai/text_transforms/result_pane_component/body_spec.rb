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

require "rails_helper"

RSpec.describe AI::TextTransforms::ResultPaneComponent::Body, type: :component do
  let(:action) { build(:ai_text_transform_action, label: "Fix grammar") }
  let(:run) { build(:ai_text_transform_run, action:, status:) }
  let(:status) { "running" }
  let(:scope) { "document" }
  let(:pane) { AI::TextTransforms::ResultPaneState.new(run:, scope:, request_id: SecureRandom.uuid) }

  subject do
    render_inline(described_class.new(pane:))
    page
  end

  before do
    run.events.build(kind: "text_delta", payload: { "delta" => "Login **works** again" }, seq: 1)
  end

  context "when generating" do
    it "shows the formatted text so far" do
      expect(subject).to have_css(".op-uc-container strong", text: "works")
    end

    it "has no raw text, apply message or banners" do
      expect(subject).to have_no_css("template", visible: :all)
      expect(subject).to have_no_test_selector("ai-text-transform-pane-apply-failed", visible: :all)
      expect(subject).to have_no_css(".Banner")
    end
  end

  context "when done" do
    let(:status) { "succeeded" }

    it "shows the formatted text" do
      expect(subject).to have_css(".op-uc-container strong", text: "works")
    end

    it "keeps the raw markdown in a template for copying" do
      subject
      expect(rendered_content)
        .to include("<template>Login **works** again</template>")
    end

    it "prepares a hidden message for a failed replace" do
      expect(subject).to have_test_selector("ai-text-transform-pane-apply-failed", visible: :hidden)
    end
  end

  context "when stopped" do
    let(:status) { "failed" }

    before { run.events.build(kind: "error", payload: { "reason" => "blocked", "message" => "Blocked" }, seq: 2) }

    it "shows the warning banner without text" do
      expect(subject).to have_css(".Banner--warning", text: "Generation stopped")
      expect(subject).to have_no_css(".op-uc-container")
    end
  end

  context "when failed" do
    let(:status) { "failed" }

    before { run.events.build(kind: "error", payload: { "reason" => "timeout", "message" => "Too slow" }, seq: 2) }

    it "shows the danger banner with the message and no text" do
      expect(subject).to have_css(".Banner--error", text: "Generation failed")
      expect(subject).to have_css(".Banner--error", text: "Too slow")
      expect(subject).to have_no_css(".op-uc-container")
    end
  end
end
