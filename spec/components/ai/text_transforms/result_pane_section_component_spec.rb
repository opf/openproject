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

require "rails_helper"

RSpec.describe AI::TextTransforms::ResultPaneSectionComponent, type: :component do
  let(:action) { build(:ai_text_transform_action, label: "Fix grammar") }
  let(:run) { build(:ai_text_transform_run, action:, status:) }
  let(:status) { "running" }
  let(:scope) { "document" }
  let(:pane) { AI::TextTransforms::ResultPaneState.new(run:, scope:, request_id: SecureRandom.uuid) }

  def render_section(section)
    render_inline(described_class.new(section:, pane:))
    page
  end

  before do
    run.events.build(kind: "text_delta", payload: { "delta" => "Login **works** again" }, seq: 1)
  end

  describe "title" do
    subject { render_section(:title) }

    it "shows the AI icon and the action label as heading" do
      expect(subject).to have_css(".octicon-sparkle")
      expect(subject).to have_css("h2", text: "Fix grammar")
    end
  end

  describe "body" do
    subject { render_section(:body) }

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

      it "keeps the raw markdown in a template" do
        subject
        expect(rendered_content).to include("<template>Login **works** again</template>")
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

  describe "footer" do
    subject { render_section(:footer) }

    context "when generating" do
      it "offers only Cancel" do
        expect(subject).to have_text("Generating…")
        expect(subject).to have_button("Cancel")
        expect(subject).to have_no_button("Replace")
      end
    end

    context "when done" do
      let(:status) { "succeeded" }

      it "offers Copy, Discard and Replace" do
        expect(subject).to have_button("Copy")
        expect(subject).to have_button("Discard")
        expect(subject).to have_css(".Button--primary", text: "Replace")
        expect(subject).to have_no_button("Cancel")
      end
    end

    context "when failed" do
      let(:status) { "failed" }

      it "offers Try again and Close" do
        expect(subject).to have_button("Try again")
        expect(subject).to have_button("Close")
        expect(subject).to have_no_button("Replace")
      end
    end

    context "when the start was rejected" do
      let(:pane) do
        AI::TextTransforms::ResultPaneState.rejected(message: "Not available", label: "Fix grammar",
                                                     scope:, request_id: SecureRandom.uuid)
      end

      it "offers only Close" do
        expect(subject).to have_button("Close")
        expect(subject).to have_no_button("Try again")
      end
    end
  end
end
