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

require "spec_helper"

RSpec.describe API::V3::EmojiReactions::EmojiReactionRepresenter do
  let(:user) { create(:user) }
  let(:reactable) { create(:work_package_journal) }
  let(:emoji_reaction) do
    create(:emoji_reaction,
           reactable: reactable,
           user: user,
           reaction: "thumbs_up")
    EmojiReactions::GroupedQueries.grouped_emoji_reactions(reactable:).first
  end
  let(:current_user) { user }
  let(:representer) { described_class.new(emoji_reaction, current_user: current_user) }
  let(:json) { representer.to_json }
  let(:parsed) { JSON.parse(json) }

  it "renders the id as reactable_id-reaction" do
    expect(parsed["id"]).to eq "#{reactable.id}-thumbs_up"
  end

  it "renders the reaction" do
    expect(parsed["reaction"]).to eq "thumbs_up"
  end

  it "renders the emoji" do
    expect(parsed["emoji"]).to eq EmojiReaction.emoji("thumbs_up")
  end

  it "renders the reactionsCount" do
    expect(parsed["reactionsCount"]).to eq 1
  end

  it "renders the firstReactionAt" do
    expect(parsed["firstReactionAt"]).to eq emoji_reaction.first_created_at.iso8601(3)
  end

  it "renders the _type" do
    expect(parsed["_type"]).to eq "EmojiReaction"
  end

  it "renders the reactingUsers link" do
    expect(parsed["_links"]["reactingUsers"]).to be_an(Array)
    expect(parsed["_links"]["reactingUsers"].first["href"]).to include("/api/v3/users/#{user.id}")
    expect(parsed["_links"]["reactingUsers"].first["title"]).to eq user.name
  end

  it "renders the reactable link" do
    expect(parsed["_links"]).to have_key("reactable")
    expect(parsed["_links"]["reactable"]["href"]).to include("/api/v3/activities/#{reactable.id}")
  end
end
