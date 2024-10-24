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

RSpec.describe EmojiReaction do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:reactable) }
  end

  describe "Enums" do
    it do
      expect(subject).to define_enum_for(:reaction)
        .with_values(
          thumbs_up: "thumbs_up",
          thumbs_down: "thumbs_down",
          grinning_face_with_smiling_eyes: "grinning_face_with_smiling_eyes",
          confused_face: "confused_face",
          heart: "heart",
          party_popper: "party_popper",
          rocket: "rocket",
          eyes: "eyes"
        )
        .backed_by_column_of_type(:string)
    end

    it "stores the reaction identifier" do
      emoji_reaction = create(:emoji_reaction, reaction: :thumbs_up)
      expect(emoji_reaction.reaction).to eq("thumbs_up")
    end
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:reaction) }

    it do
      emoji_reaction = create(:emoji_reaction)
      expect(emoji_reaction).to validate_uniqueness_of(:user_id).scoped_to(%i[reactable_type reactable_id reaction])
    end
  end

  describe ".available_emojis" do
    it "returns the available emojis as HTML codes" do
      expect(described_class.available_emojis).to eq(["👍", "👎", "😄", "😕", "❤", "🎉", "🚀", "👀"])
    end
  end

  describe ".emoji" do
    it "returns the emoji for a given reaction" do
      expect(described_class.emoji("thumbs_up")).to eq("👍")
    end

    it "returns nil if no reaction exists with given name" do
      expect(described_class.emoji("rock_on")).to be_nil
    end
  end
end
