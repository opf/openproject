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

module EmojiReactions
  module GroupedQueries
    class << self
      def grouped_work_package_journals_emoji_reactions(work_package)
        grouped_emoji_reactions(reactable_id: journal_ids_for(work_package), reactable_type: "Journal")
      end

      def grouped_work_package_journals_emoji_reactions_by_reactable(work_package)
        grouped_emoji_reactions_by_reactable(reactable_id: journal_ids_for(work_package), reactable_type: "Journal")
      end

      def grouped_emoji_reactions_by_reactable(**)
        grouped_emoji_reactions(**)
          .each_with_object(Hash.new { |h, k| h[k] = {} }) do |row, hash|
          hash[row.reactable_id][row.reaction.to_sym] = {
            count: row.reactions_count,
            users: row.reacting_users.map { |(id, name)| { id:, name: } }
          }
        end
      end

      def grouped_emoji_reactions(**)
        reactable_id, reactable_type = extract_reactable_id_and_type(**)

        EmojiReaction
          .select(emoji_reactions_group_selection_sql)
          .joins(:user)
          .includes(:reactable)
          .where(reactable_id:, reactable_type:)
          .group("emoji_reactions.reactable_type, emoji_reactions.reactable_id, emoji_reactions.reaction")
          .order(first_created_at: :asc)
      end

      private

      def emoji_reactions_group_selection_sql
        <<~SQL.squish
          emoji_reactions.reactable_id, emoji_reactions.reactable_type, emoji_reactions.reaction,
          COUNT(emoji_reactions.id) as reactions_count,
          json_agg(
            json_build_array(users.id, #{user_name_concat_format_sql})
            ORDER BY emoji_reactions.created_at
          ) as reacting_users,
          MIN(emoji_reactions.created_at) as first_created_at
        SQL
      end

      def user_name_concat_format_sql
        case Setting.user_format
        when :firstname_lastname
          "concat_ws(' ', users.firstname, users.lastname)"
        when :firstname
          "users.firstname"
        when :lastname_firstname
          "concat_ws(' ', users.lastname, users.firstname)"
        when :lastname_comma_firstname
          "concat_ws(', ', users.lastname, users.firstname)"
        when :lastname_n_firstname
          "concat_ws('', users.lastname, users.firstname)"
        when :username
          "users.login"
        else
          raise ArgumentError, "Unsupported user format: #{Setting.user_format}"
        end
      end

      def extract_reactable_id_and_type(**kwargs)
        case kwargs
        in { reactable: reactable }
          [reactable.id, reactable.class.name]
        in { reactable_id: id, reactable_type: type }
          [id, type]
        else
          raise ArgumentError, "Must specify either reactable or both reactable_id and reactable_type"
        end
      end

      def journal_ids_for(reactable)
        reactable.journals.internal_visible.select(:id).pluck(:id)
      end
    end
  end
end
