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

RSpec.describe AI::Assistance::ProposalItemComponent, type: :component do
  let(:message) { create(:ai_assistant_chat_message) }
  let(:work_package_id) { message.chat.work_package_id }
  let(:proposal) do
    create(:ai_assistant_proposal, :finding,
           message:,
           text: "<script>alert(1)</script> is wrong",
           evidence: [{ "text" => "<b>#1</b>", "work_package_id" => work_package_id },
                      { "text" => "PR", "url" => "javascript:alert(1)" }])
  end

  subject(:rendered) { render_inline(described_class.new(proposal:)) }

  it "escapes the text and the evidence" do
    expect(rendered.to_html).not_to include("<script>")
    expect(rendered.to_html).not_to include("<b>#1</b>")
    expect(rendered).to have_text("<script>alert(1)</script> is wrong")
  end

  it "links work package evidence and does not link unsafe URLs" do
    expect(rendered).to have_link("<b>#1</b>", href: "/work_packages/#{work_package_id}")
    expect(rendered).to have_no_link("PR")
  end

  it "shows a finding's severity and offers to dismiss it" do
    expect(rendered).to have_text("Medium")
    expect(rendered).to have_test_selector("ai-assistance-dismiss")
  end

  context "with a finding without an area" do
    before { proposal.update!(area: nil) }

    it "shows its severity and no area" do
      expect(rendered).to have_text("Medium")
      expect(rendered).to have_no_text("Content")
    end
  end

  context "with a plain proposal" do
    let(:proposal) { create(:ai_assistant_proposal, message:, text: "A clearer description") }

    it "shows its text without a severity or evidence" do
      expect(rendered).to have_text("A clearer description")
      expect(rendered).to have_no_text("Medium")
      expect(rendered).not_to have_test_selector("ai-assistance-evidence")
    end
  end

  context "when dismissed" do
    before { proposal.update!(state: "dismissed") }

    it "shows the state and no actions" do
      expect(rendered).to have_text("Dismissed")
      expect(rendered).not_to have_test_selector("ai-assistance-dismiss")
    end
  end
end
