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

module API
  module V3
    module Activities
      class ActivityRepresenter < ::API::Decorators::Single
        include API::V3::Utilities
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty
        include API::Caching::CachedRepresenter
        include ::API::V3::Attachments::AttachableRepresenterMixin
        include ActivityPropertyFormatters

        self_link path: :activity,
                  title_getter: ->(*) {}

        link :workPackage do
          {
            href: api_v3_paths.work_package(represented.journable.id),
            title: represented.journable.subject.to_s
          }
        end

        link :user do
          {
            href: api_v3_paths.user(represented.user_id)
          }
        end

        link :update do
          next unless current_user_allowed_to_edit?

          {
            href: api_v3_paths.activity(represented.id),
            method: :patch
          }
        end

        link :emojiReactions do
          {
            href: api_v3_paths.emoji_reactions_by_activity_comment(represented.id)
          }
        end

        property :id,
                 render_nil: true

        formattable_property :notes,
                             as: :comment,
                             getter: ->(*) { formatted_notes(represented) }

        property :details,
                 exec_context: :decorator,
                 getter: ->(*) { formatted_details(represented) },
                 render_nil: true

        property :version, render_nil: true

        property :internal

        property :work_package,
                 embedded: true,
                 exec_context: :decorator,
                 if: ->(*) { embed_links },
                 uncacheable: true

        property :emoji_reactions,
                 embedded: true,
                 exec_context: :decorator,
                 if: ->(*) { embed_links },
                 uncacheable: true

        date_time_property :created_at
        date_time_property :updated_at

        def _type
          if represented.noop? || represented.notes.present?
            "Activity::Comment"
          else
            "Activity"
          end
        end

        def work_package
          return unless represented.journable.is_a?(WorkPackage)

          API::V3::WorkPackages::WorkPackageRepresenter
            .create(represented.journable,
                    current_user: current_user,
                    embed_links: false)
        end

        def emoji_reactions
          return unless represented.journable.is_a?(WorkPackage)

          emoji_reactions = ::EmojiReactions::GroupedQueries.grouped_emoji_reactions(reactable: represented)
          API::V3::EmojiReactions::EmojiReactionCollectionRepresenter
            .new(emoji_reactions,
                 self_link: api_v3_paths.emoji_reactions_by_activity_comment(represented.id),
                 current_user:)
        end

        private

        def current_user_allowed_to_edit?
          represented.editable_by?(current_user)
        end
      end
    end
  end
end
