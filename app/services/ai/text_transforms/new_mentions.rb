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

module AI
  module TextTransforms
    # Saving notifies everyone a text newly mentions, so the model output may only keep mentions of users
    # and groups the input already mentioned. The others become plain text the user can mention again.
    class NewMentions
      PATTERN = Notifications::CreateFromModelService::MENTION_PATTERN
      TAG = /<mention\b(?:[^>"']|"[^"]*"|'[^']*')*>?/i
      PRINCIPAL_TYPES = %w[user group].freeze

      def initialize(input)
        @input = input.to_s
        @found = false
      end

      def found? = @found

      def new_in?(*texts)
        found_unless(texts.none? { |text| text.scan(PATTERN).any? { !known?(*target(it).first(2)) } })
      end

      def new_tag?(attributes)
        type = attributes["data-type"]
        return false unless PRINCIPAL_TYPES.include?(type)

        found_unless(known?(type.to_sym, attributes["data-id"].to_i))
      end

      # Finds every mention the notification service would, code and markup included.
      def convert(text)
        without_new_tags(text).gsub(PATTERN) do
          mention = Regexp.last_match
          type, key, tag = target(mention.captures)
          next mention[0] if known?(type, key)

          @found = true
          tag ? "" : plain_text(type, mention[0])
        end
      end

      private

      # The service's pattern ends some tags before their closing bracket, so whole tags go first.
      def without_new_tags(text)
        text.gsub(TAG) { |tag| new_tag?(Nokogiri::HTML5.fragment(tag).element_children.first || {}) ? "" : tag }
      end

      def found_unless(known)
        @found ||= !known
        !known
      end

      # The pattern captures a user's tag ids and hash id, then a login, then a group's tag ids and hash id.
      def target(captures)
        user_ids = captures[0, 3]
        login = captures[3]
        group_ids = captures[4, 3]
        return [:login, login, false] if login

        type, ids = user_ids.any? ? [:user, user_ids] : [:group, group_ids]
        [type, ids.compact.first.to_i, ids.last.nil?]
      end

      # A tag only loses itself and keeps the text after it. Without its hash an id does not become a
      # work package link either.
      def plain_text(type, mention)
        type == :login ? mention.sub(":", ": ") : mention.sub("#", " ")
      end

      def known?(type, key)
        case type
        when :login then input_mentions[:logins].include?(key) || input_mentions[:users].include?(user_id(key))
        when :user then input_mentions[:users].include?(key)
        else input_mentions[:groups].include?(key)
        end
      end

      def user_id(login)
        User.where(login:).pick(:id)
      end

      def input_mentions
        @input_mentions ||= begin
          targets = @input.scan(PATTERN).map { target(it) }
          keys = ->(wanted) { targets.filter_map { |type, key| key if type == wanted } }
          { logins: keys[:login], users: keys[:user] + User.where(login: keys[:login]).pluck(:id), groups: keys[:group] }
        end
      end
    end
  end
end
