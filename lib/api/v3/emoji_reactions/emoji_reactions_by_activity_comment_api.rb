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

module API
  module V3
    module EmojiReactions
      class EmojiReactionsByActivityCommentAPI < ::API::OpenProjectAPI
        resource :emoji_reactions do
          helpers do
            def reactable
              @activity
            end

            def get_emoji_reactions_self_path
              api_v3_paths.emoji_reactions_by_activity_comment(reactable.id)
            end

            def grouped_emoji_reactions
              ::EmojiReactions::GroupedQueries.grouped_emoji_reactions(reactable:)
            end

            def activity_comment?
              reactable.notes.present?
            end
          end

          get do
            EmojiReactionCollectionRepresenter.new(grouped_emoji_reactions,
                                                   self_link: get_emoji_reactions_self_path,
                                                   current_user: User.current)
          end

          params do
            requires :reaction, type: String, desc: "The emoji reaction to add/remove",
                                values: ::EmojiReaction::EMOJI_MAP.keys.map(&:to_s)
          end

          patch do
            unless activity_comment?
              raise ::API::Errors::BadRequest.new(
                I18n.t("api_v3.errors.bad_request.emoji_reactions_activity_type_not_supported")
              )
            end

            toggle_service = ::EmojiReactions::ToggleEmojiReactionService.call(
              user: current_user,
              reactable: reactable,
              reaction: params[:reaction]
            )

            if toggle_service.success?
              EmojiReactionCollectionRepresenter.new(grouped_emoji_reactions,
                                                     self_link: get_emoji_reactions_self_path,
                                                     current_user:)
            else
              fail ::API::Errors::ErrorBase.create_and_merge_errors(toggle_service.errors)
            end
          end
        end
      end
    end
  end
end
