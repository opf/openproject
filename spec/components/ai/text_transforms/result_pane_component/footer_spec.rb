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
  let(:request_id) { SecureRandom.uuid }
  let(:context) { AI::TextTransforms::Context.none }
  let(:pane) { AI::TextTransforms::ResultPaneState.new(run:, scope:, request_id:, context:) }
  let(:close_form_id) { AI::TextTransforms::ResultPaneHelpers::CLOSE_FORM_ID }
  let(:apply_form_id) { AI::TextTransforms::ResultPaneHelpers::APPLY_FORM_ID }
  let(:retry_form_id) { AI::TextTransforms::ResultPaneHelpers::RETRY_FORM_ID }
  let(:close_form) { "form##{close_form_id}" }
  let(:apply_form) { "form##{apply_form_id}" }
  let(:retry_form) { "form##{retry_form_id}" }

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

  it "renders the close form" do
    expect(subject).to have_css("#{close_form}[action='/ai/text_transform_panes/#{run.uuid}']")
    expect(subject.find(close_form)).to have_field("_method", type: :hidden, with: "delete")
  end

  it "exposes the pane state for polling" do
    state = subject.find("[data-ai-text-transform-pane-target='state']", visible: :hidden)

    expect(state).to match_css("[data-state='generating'][data-run='#{run.uuid}'][data-seq='1'][data-request-id='#{request_id}']")
    expect(state["data-poll-url"]).to eq("/ai/text_transform_panes/#{run.uuid}?request_id=#{request_id}&scope=#{scope}")
  end

  it "leaves out the context ids that are not set" do
    expect(subject).to have_no_css(%w[work_package_id project_id type_id].map { "input[name='#{it}']" }.join(", "),
                                   visible: :hidden)
  end

  context "with a work package" do
    let(:status) { "failed" }
    let(:work_package) { build_stubbed(:work_package) }
    let(:context) { AI::TextTransforms::Context.for_work_package(work_package) }

    it "carries the pane parameters with only the work package id as context" do
      form = subject.find(retry_form)
      expect(form).to have_field("request_id", type: :hidden, with: request_id)
      expect(form).to have_field("scope", type: :hidden, with: scope)
      expect(form).to have_field("work_package_id", type: :hidden, with: work_package.id)
      expect(form).to have_no_field("project_id", type: :hidden)
      expect(form).to have_no_field("type_id", type: :hidden)
    end
  end

  context "when generating" do
    it "offers only Cancel" do
      expect(subject).to have_text("Generating…")
      expect(subject).to have_css("button[type=submit][form='#{close_form_id}']", text: "Cancel")
      expect(subject).to have_no_button("Replace")
      expect(subject).to have_no_css("#{apply_form}, #{retry_form}")
    end
  end

  context "when done" do
    let(:status) { "succeeded" }

    it "offers Discard and Replace" do
      expect(subject).to have_css("button[type=submit][form='#{close_form_id}']", text: "Discard")
      expect(subject).to have_css(".Button--primary[type=submit][form='#{apply_form_id}']", text: "Replace")
      expect(subject).to have_no_button("Cancel")
    end

    it "renders the apply form" do
      expect(subject).to have_css("#{apply_form}[action='/ai/text_transform_panes/#{run.uuid}/apply']")
      expect(subject).to have_no_css(retry_form)
    end

    it "copies the raw text with a clipboard button" do
      expect(subject).to have_element(:"clipboard-copy", "aria-label": "Copy", value: "Login **works** again")
    end
  end

  context "when failed" do
    let(:status) { "failed" }

    it "offers Try again and Close" do
      expect(subject).to have_css("button[type=submit][form='#{retry_form_id}']", text: "Try again")
      expect(subject).to have_css("button[type=submit][form='#{close_form_id}']", text: "Close")
      expect(subject).to have_no_button("Replace")
    end

    it "renders the retry form for the run" do
      expect(subject).to have_css("#{retry_form}[action='/ai/text_transform_panes']")
      expect(subject.find(retry_form)).to have_field("retry_of", type: :hidden, with: run.uuid)
      expect(subject).to have_no_css(apply_form)
    end
  end

  context "when cancelled" do
    let(:status) { "cancelled" }

    it "offers no Try again" do
      expect(subject).to have_button("Close")
      expect(subject).to have_no_button("Try again")
      expect(subject).to have_no_css(retry_form)
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
      expect(subject).to have_css(close_form, count: 1)
      expect(subject).to have_no_css("#{apply_form}, #{retry_form}")
    end

    it "has nothing to poll" do
      expect(subject).to have_css("[data-state='failed']:not([data-poll-url]):not([data-run])", visible: :hidden)
    end
  end
end
