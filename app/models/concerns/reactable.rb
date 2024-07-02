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

module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :emoji_reactions, as: :reactable, dependent: :destroy
  end

  def add_reaction(user, emoji)
    emoji_reactions.create(user: user, emoji: emoji)
  end

  def remove_reaction(user, emoji)
    emoji_reactions.find_by(user: user, emoji: emoji)&.destroy
  end

  def grouped_emoji_reactions
    emoji_reactions.group(:emoji).count
  end

  def detailed_grouped_emoji_reactions
    emoji_reactions
      .select('emoji, COUNT(*) as count, ARRAY_AGG(user_id) as user_ids')
      .group(:emoji)
      .order('emoji ASC')
      .map do |result|
        users = User.where(id: result.user_ids).select(:id, :firstname, :lastname)
        {
          emoji: result.emoji,
          count: result.count,
          users: users.map { |u| { id: u.id, name: u.name } }
        }
      end.index_by { |r| r[:emoji] }
  end

  def available_emojis
    EmojiReaction.available_emojis.sort
  end

  def available_untaken_emojis
    (EmojiReaction.available_emojis - detailed_grouped_emoji_reactions.keys).sort
  end
end
