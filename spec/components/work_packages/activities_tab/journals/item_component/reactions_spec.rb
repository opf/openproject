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
#
require "spec_helper"

RSpec.describe WorkPackages::ActivitiesTab::Journals::ItemComponent::Reactions, type: :component do
  let(:journal) { build_stubbed(:work_package_journal) }

  context "with reactions" do
    before do
      allow(journal).to receive(:detailed_grouped_emoji_reactions).and_return(mock_detailed_grouped_emoji_reactions)
    end

    it "renders the reactions" do
      render_inline(described_class.new(journal:))

      {
        thumbs_up: {
          count: 3, tooltip_text: "Bob Bobbit, Bob Bobbit and Bob Bobbit",
          aria_label: "thumbs up by Bob Bobbit, Bob Bobbit and Bob Bobbit"
        },
        thumbs_down: {
          count: 1, tooltip_text: "Bob Bobbit", aria_label: "thumbs down by Bob Bobbit"
        },
        eyes: {
          count: 20, tooltip_text: "Bob Bobbit, Bob Bobbit, Bob Bobbit, Bob Bobbit, Bob Bobbit and 15 others",
          aria_label: "eyes by Bob Bobbit, Bob Bobbit, Bob Bobbit, Bob Bobbit, Bob Bobbit and 15 others"
        },
        rocket: {
          count: 5, tooltip_text: "Bob Bobbit, Bob Bobbit, Bob Bobbit, Bob Bobbit and Bob Bobbit",
          aria_label: "rocket by Bob Bobbit, Bob Bobbit, Bob Bobbit, Bob Bobbit and Bob Bobbit"
        },
        confused_face: {
          count: 6,
          tooltip_text: "Bob Bobbit, Bob Bobbit, Bob Bobbit, Bob Bobbit, Bob Bobbit and 1 other",
          aria_label: "confused face by Bob Bobbit, Bob Bobbit, Bob Bobbit, Bob Bobbit, Bob Bobbit and 1 other"
        }
      }.each { |reaction, details| expect_emoji_reaction(reaction:, **details) }
    end
  end

  context "with no reactions" do
    before do
      allow(journal).to receive(:detailed_grouped_emoji_reactions).and_return([])
    end

    it "does not render" do
      render_inline(described_class.new(journal:))

      expect(page.text).to be_empty
    end
  end

  def expect_emoji_reaction(reaction:, count:, tooltip_text:, aria_label:)
    expect(page).to have_test_selector("reaction-#{reaction}", text: "#{EmojiReaction.emoji(reaction)} #{count}",
                                                               aria: { label: aria_label })
    expect(page).to have_test_selector("reaction-tooltip-#{reaction}", text: tooltip_text)
  end

  def mock_detailed_grouped_emoji_reactions
    users = build_stubbed_list(:user, 20).map { |user| { id: user.id, name: user.name } }

    {
      EmojiReaction.emoji(:thumbs_up) => { reaction: "thumbs_up", users: users.sample(3), count: 3 },
      EmojiReaction.emoji(:thumbs_down) => { reaction: "thumbs_down", users: users.sample(1), count: 1 },
      EmojiReaction.emoji(:eyes) => { reaction: "eyes", users: users, count: 20 },
      EmojiReaction.emoji(:rocket) => { reaction: "rocket", users: users.sample(5), count: 5 },
      EmojiReaction.emoji(:confused_face) => { reaction: "confused_face", users: users.sample(6), count: 6 }
    }
  end
end
