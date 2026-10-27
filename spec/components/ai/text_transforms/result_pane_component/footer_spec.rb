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

RSpec.describe AI::TextTransforms::ResultPaneComponent::Footer, type: :component do
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

  it "lets the grip drag the pane" do
    expect(subject).to have_css(".op-ai-result-pane--grip[data-action='pointerdown->ai-text-transform-pane#beginDrag']")
  end

  context "when generating" do
    it "offers only Cancel" do
      expect(subject).to have_text("Generating…")
      expect(subject).to have_button("Cancel")
      expect(subject).to have_no_button("Replace")
    end
  end

  context "when done" do
    let(:status) { "succeeded" }

    it "offers Discard and Replace" do
      expect(subject).to have_button("Discard")
      expect(subject).to have_css(".Button--primary", text: "Replace")
      expect(subject).to have_no_button("Cancel")
    end

    it "copies the raw text with a clipboard button" do
      expect(subject).to have_element(:"clipboard-copy", "aria-label": "Copy", value: "Login **works** again")
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
