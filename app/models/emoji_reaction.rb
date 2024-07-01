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
  EMOJI_MAP = {
    thumbs_up: "&#x1F44D;",
    thumbs_down: "&#x1F44E;",
    grinning_face_with_smiling_eyes: "&#x1F604;",
    confused_face: "&#x1F615;",
    heart: "&#x2764;",
    party_popper: "&#x1F389;",
    rocket: "&#x1F680;",
    eyes: "&#x1F440;"
  }.freeze

  AVAILABLE_EMOJIS = EMOJI_MAP.values.freeze

  belongs_to :user
  belongs_to :reactable, polymorphic: true

  validates :emoji, presence: true, inclusion: { in: AVAILABLE_EMOJIS }
  validates :user_id, uniqueness: { scope: [:reactable_type, :reactable_id, :emoji] }

  def self.available_emojis
    AVAILABLE_EMOJIS
  end

  def self.shortcode(html_code)
    EMOJI_MAP.key(html_code)&.to_s&.prepend(':')&.concat(':') || html_code
  end
end
