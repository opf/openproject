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

RSpec.describe MeetingAgendaItems::VoteControlsComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  let(:meeting) { create(:meeting, project:, agenda_sorting_mode: :vote_based) }
  let(:item) { create(:meeting_agenda_item, meeting:) }
  let(:voting_enabled) { true }
  let(:component) { described_class.new(meeting_agenda_item: item, voting_enabled:) }

  before { User.current = user }

  it "shows a zero vote count and accessible voting buttons" do
    render_inline(component)

    expect(page).to have_text("Votes: 0")
    expect(page).to have_css('button[aria-label="Upvote"][aria-pressed="false"]', text: "👍")
    expect(page).to have_css('button[aria-label="Downvote"][aria-pressed="false"]', text: "👎")
  end

  it "shows negative votes and the selected action" do
    item.emoji_reactions.create!(user:, reaction: :thumbs_down)
    render_inline(component)

    expect(page).to have_text("Votes: -1")
    expect(page).to have_css('button[aria-label="Remove downvote"][aria-pressed="true"]')
  end

  context "when voting is disabled" do
    let(:voting_enabled) { false }

    it "shows the count without actions" do
      render_inline(component)

      expect(page).to have_text("Votes: 0")
      expect(page).to have_no_button
    end
  end
end
