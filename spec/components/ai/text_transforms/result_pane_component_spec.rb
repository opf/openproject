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

RSpec.describe AI::TextTransforms::ResultPaneComponent, type: :component do
  let(:run) { build(:ai_text_transform_run, :succeeded, action: build(:ai_text_transform_action, label: "Fix grammar")) }
  let(:pane) { AI::TextTransforms::ResultPaneState.new(run:, scope: "document", request_id: SecureRandom.uuid) }

  subject do
    render_inline(described_class.new(pane:))
    page
  end

  before do
    run.events.build(kind: "completed", payload: { "text" => "Login works again." }, seq: 1)
  end

  it "renders a labeled, non-modal dialog" do
    expect(subject).to have_css("[role=dialog][aria-label='AI result'].op-ai-result-pane")
    expect(subject).to have_no_css("dialog")
  end

  it "composes a BorderBox with header, body and footer" do
    expect(subject).to have_css(".Box .Box-header h2", text: "Fix grammar")
    expect(subject).to have_css(".Box .Box-body", text: "Login works again.")
    expect(subject).to have_css(".Box .Box-footer", text: "Replace")
  end

  it "attaches the floating pane controller to the wrapper" do
    expect(subject).to have_css(
      "[data-test-selector='ai-text-transform-result'][data-controller='ai-text-transform-pane']" \
      "[data-ai-text-transform-pane-close-form-value='#{AI::TextTransforms::ResultPaneHelpers::CLOSE_FORM_ID}']" \
      "[data-action='keydown.esc->ai-text-transform-pane#close resize@window->ai-text-transform-pane#keepInViewport']"
    )
  end

  it "makes the pane focusable and draggable by its header" do
    expect(subject).to have_css(".op-ai-result-pane[tabindex='-1'][data-ai-text-transform-pane-target='pane']")
    expect(subject).to have_css(".Box-header[data-action='pointerdown->ai-text-transform-pane#beginDrag']")
  end

  it "has a close button in the header" do
    expect(subject).to have_css(".Box-header button[aria-label='Close'][data-action='click->ai-text-transform-pane#close']")
  end

  it "renders each section in its own streamable wrapper" do
    %w[title body footer].each do |section|
      expect(subject).to have_css("#ai-text-transforms-result-pane-component-#{section}")
    end
  end

  it "renders the four resize handles with the OpenProject resizer icons" do
    expect(subject).to have_css(".op-ai-result-pane--resize[aria-hidden=true]", count: 4)
    expect(subject).to have_css(".op-ai-result-pane--resize .octicon-op-resizer-vertical-lines", count: 2)
    expect(subject).to have_css(".op-ai-result-pane--resize .octicon-op-resizer-bottom-right", count: 2)
  end

  it "resizes the pane from each handle's edge" do
    %w[left right bottom-left bottom-right].each do |edge|
      expect(subject).to have_css(
        ".op-ai-result-pane--resize[data-edge='#{edge}'][data-action='pointerdown->ai-text-transform-pane#beginResize']"
      )
    end
  end
end
