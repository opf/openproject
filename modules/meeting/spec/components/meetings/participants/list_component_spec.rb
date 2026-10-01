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
require_module_spec_helper

RSpec.describe Meetings::Participants::ListComponent, type: :component do
  let(:meeting) { create(:meeting) }

  subject(:rendered_component) do
    meeting.reload
    render_inline(described_class.new(meeting:))
  end

  context "with participants" do
    let!(:participant) do
      create(:meeting_participant, meeting:, user: create(:user, firstname: "Ada", lastname: "Lovelace"))
    end

    it_behaves_like "rendering Box", row_count: 1

    it "renders the participants header with its title and count", :aggregate_failures do
      expect(rendered_component).to have_css(".Box-header") do |header|
        expect(header).to have_text(I18n.t("meeting.participants.label.participants"))
        expect(header).to have_css(".Counter", text: "1")
      end
    end

    it "renders a row per participant" do
      expect(rendered_component).to have_css(".Box-row", text: "Ada Lovelace")
    end

    it "keeps the heading free of layouts and controls" do
      expect(rendered_component).to have_css(".Box-header h4") do |heading|
        expect(heading).to have_no_css("div, button, a")
      end
    end

    it "renders no mark-all-attended action when the meeting is not in progress" do
      expect(rendered_component)
        .to have_no_link(I18n.t("meeting.participants.label.mark_all_as_attended"))
    end

    context "when the meeting is in progress with unattended participants" do
      let(:meeting) { create(:meeting, state: :in_progress) }

      it "renders mark-all-attended as a header action outside the heading", :aggregate_failures do
        expect(rendered_component).to have_link(I18n.t("meeting.participants.label.mark_all_as_attended"))
        expect(rendered_component).to have_no_css("h4 a")
      end
    end
  end

  context "without participants" do
    it_behaves_like "rendering an empty Border Box List",
                    heading: I18n.t("meeting.participants.blankslate.heading"), icon: :people
  end
end
