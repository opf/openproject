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
      QUOTED_LINES = Notifications::CreateFromModelService::QUOTED_LINES_PATTERN
      TAG = %r{<(/?)mention\b(?:[^>"']|"[^"]*"|'[^']*')*>?}i
      PRINCIPAL_TYPE = /\s*data-type="(?:user|group)"/
      PRINCIPAL_TYPES = %w[user group].freeze

      def initialize(input)
        @input = input.to_s
        @found = false
        @user_ids = Hash.new { |ids, login| ids[login] = User.where(login:).pick(:id) }
      end

      def found? = @found

      def new_in?(*texts)
        found_unless(texts.compact.none? { |text| text.scan(PATTERN).any? { !known?(*target(it).first(2)) } })
      end

      def new_tag?(attributes)
        type = attributes["data-type"]
        return false unless PRINCIPAL_TYPES.include?(type)

        found_unless(known?(type.to_sym, attributes["data-id"].to_i))
      end

      def hidden_in?(fragment)
        new_in?(*fragment.xpath(".//text()").map(&:text), *fragment.xpath(".//@*").map(&:value)) ||
          fragment.css("mention").any? { new_tag?(it) }
      end

      def convert(text)
        without_new_tags(text).gsub(PATTERN) do
          mention = Regexp.last_match
          type, key, tag = target(mention.captures)
          next mention[0] if known?(type, key)

          @found = true
          tag ? mention[0].sub(PRINCIPAL_TYPE, "") : plain_text(type, mention[0])
        end
      end

      private

      def without_new_tags(text)
        open_tags = []
        text.gsub(TAG) do |tag|
          closing = Regexp.last_match[1].present?
          removed = closing ? open_tags.pop : open_tags.push(new_tag?(attributes(tag))).last
          removed ? "" : tag
        end
      end

      def attributes(tag)
        Nokogiri::HTML5.fragment(tag).element_children.first || {}
      end

      def found_unless(known)
        @found ||= !known
        !known
      end

      def target(captures)
        login = captures[3]
        return [:login, login, false] if login

        user_ids = captures[0, 3]
        type, ids = user_ids.any? ? [:user, user_ids] : [:group, captures[4, 3]]
        [type, ids.compact.first.to_i, ids.last.nil?]
      end

      # Without its hash, an id does not turn into a work package link either.
      def plain_text(type, mention)
        type == :login ? mention.sub(":", ": ") : mention.sub("#", " ")
      end

      def known?(type, key)
        case type
        when :login then input_mentions[:logins].include?(key) || input_mentions[:users].include?(@user_ids[key])
        when :user then input_mentions[:users].include?(key)
        else input_mentions[:groups].include?(key)
        end
      end

      def input_mentions
        @input_mentions ||= begin
          targets = @input.gsub(QUOTED_LINES, "").scan(PATTERN).map { target(it) }
          keys = ->(wanted) { targets.filter_map { |type, key| key if type == wanted } }
          { logins: keys[:login], users: keys[:user] + keys[:login].filter_map { @user_ids[it] }, groups: keys[:group] }
        end
      end
    end
  end
end
