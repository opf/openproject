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
      expect(subject).to define_enum_for(:emoji)
        .with_values(
          thumbs_up: "\u{1F44D}",
          thumbs_down: "\u{1F44E}",
          grinning_face_with_smiling_eyes: "\u{1F604}",
          confused_face: "\u{1F615}",
          heart: "\u{2764}",
          party_popper: "\u{1F389}",
          rocket: "\u{1F680}",
          eyes: "\u{1F440}"
        )
        .backed_by_column_of_type(:string)
    end
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:emoji) }

    it do
      emoji_reaction = create(:emoji_reaction)
      expect(emoji_reaction).to validate_uniqueness_of(:user_id).scoped_to(%i[reactable_type reactable_id emoji])
    end
  end

  describe ".available_emojis" do
    it "returns the available emojis as HTML codes" do
      expect(described_class.available_emojis).to eq(["👍", "👎", "😄", "😕", "❤", "🎉", "🚀", "👀"])
    end
  end

  describe ".emoji_name" do
    it "returns the emoji name for a given unicode", :aggregate_failures do
      expect(described_class.emoji_name("\u{1F44D}")).to eq("thumbs up")
      expect(described_class.emoji_name("😄")).to eq("grinning face with smiling eyes")
    end

    it "returns nil if no emoji exists with given unicode" do
      expect(described_class.emoji_name("\u{1F607}")).to be_nil
      expect(described_class.emoji_name("🤗")).to be_nil
    end
  end
end
