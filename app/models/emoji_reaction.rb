#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class EmojiReaction < ApplicationRecord
  # See: https://unicode.org/Public/emoji/latest/emoji-test.txt
  EMOJI_MAP = {
    thumbs_up: "\u{1F44D}",
    thumbs_down: "\u{1F44E}",
    grinning_face_with_smiling_eyes: "\u{1F604}",
    confused_face: "\u{1F615}",
    heart: "\u{2764}",
    party_popper: "\u{1F389}",
    rocket: "\u{1F680}",
    eyes: "\u{1F440}"
  }.freeze

  AVAILABLE_EMOJIS = EMOJI_MAP.values.freeze

  belongs_to :user
  belongs_to :reactable, polymorphic: true

  validates :reaction, presence: true
  validates :user_id, uniqueness: { scope: %i[reactable_type reactable_id reaction] }

  enum :reaction, EMOJI_MAP.each_with_object({}) { |(k, _v), h| h[k] = k.to_s }

  def self.available_emojis
    AVAILABLE_EMOJIS
  end

  def self.emoji(reaction)
    EMOJI_MAP[reaction.to_sym]
  end
end
