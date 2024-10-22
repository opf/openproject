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

  def available_emoji_reactions
    (EmojiReaction.reactions.values - emoji_reactions.pluck(:reaction).uniq).index_by do |reaction|
      EmojiReaction.emoji(reaction)
    end.sort
  end

  def detailed_grouped_emoji_reactions
    # TODO: Refactor this to be database agnostic
    # fetch all emoji reactions and group them by emoji with their count and user ids
    reaction_groups = emoji_reactions
      .select("reaction, COUNT(*) as count, ARRAY_AGG(user_id) as user_ids")
      .group(:reaction)
      .order("reaction ASC")

    # avoid N+1 queries by preloading all reacting users
    user_ids = reaction_groups.flat_map(&:user_ids).uniq
    users = User.where(id: user_ids).select(:id, :firstname, :lastname).index_by(&:id)

    # convert the result to a hash indexed by reaction suitable for rendering
    reaction_groups.map do |result|
      {
        reaction: result.reaction,
        emoji: EmojiReaction.emoji(result.reaction),
        count: result.count,
        users: result.user_ids.map { |id| { id:, name: users[id].name } }
      }
    end.index_by { |r| r[:emoji] }
  end
end
