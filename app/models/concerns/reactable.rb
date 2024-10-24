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

  class_methods do
    def grouped_journal_emoji_reactions(journal)
      grouped_emoji_reactions_by_reactable(reactable_id: journal.id, reactable_type: "Journal")
    end

    def grouped_work_package_journals_emoji_reactions(work_package, last_updated_at: nil)
      grouped_emoji_reactions_by_reactable(reactable_id: work_package.journal_ids, reactable_type: "Journal", last_updated_at:)
    end

    def grouped_emoji_reactions_by_reactable(reactable_id:, reactable_type:, last_updated_at: nil)
      grouped_emoji_reactions(reactable_id:, reactable_type:, last_updated_at:).each_with_object({}) do |row, hash|
        hash[row.reactable_id] ||= {}
        hash[row.reactable_id][row.reaction.to_sym] = {
          count: row.count,
          users: row.user_details.map { |(id, name)| { id:, name: } }
        }
      end
    end

    def grouped_emoji_reactions(reactable_id:, reactable_type:, last_updated_at: nil)
      query = EmojiReaction
        .select("emoji_reactions.reactable_id, emoji_reactions.reaction, COUNT(emoji_reactions.id) as count, " \
                "json_agg(json_build_array(users.id, #{user_name_concat_format_sql}) ORDER BY emoji_reactions.created_at) as user_details") # rubocop:disable Layout/LineLength
        .joins(:user)
        .where(reactable_id:, reactable_type:)

      query = query.where("emoji_reactions.updated_at > ?", last_updated_at) if last_updated_at

      query.group("emoji_reactions.reactable_id, emoji_reactions.reaction")
    end

    private

    def user_name_concat_format_sql
      case Setting.user_format
      when :firstname_lastname
        "concat_ws(' ', users.firstname, users.lastname)"
      when :firstname
        "users.firstname"
      when :lastname_firstname
        "concat_ws(' ', users.lastname, users.firstname)"
      when :lastname_coma_firstname
        "concat_ws(', ', users.lastname, users.firstname)"
      when :lastname_n_firstname
        "concat_ws('', users.lastname, users.firstname)"
      when :username
        "users.login"
      else
        raise ArgumentError, "Unsupported user format: #{Setting.user_format}"
      end
    end
  end

  def available_emoji_reactions
    (EmojiReaction.reactions.values - emoji_reactions.pluck(:reaction).uniq).index_by do |reaction|
      EmojiReaction.emoji(reaction)
    end.sort
  end
end
