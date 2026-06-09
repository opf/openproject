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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackages
  module ActivitiesTab
    # Translates a client's "what changed since I last polled?" question into the
    # turbo-stream mutations the activities tab needs. It owns the journal/notification
    # queries and the decision of what to render; emission is delegated to the +sink+
    # (the controller, which carries OpTurbo::ComponentStream), so the streaming
    # mechanics stay where the framework keeps them.
    class UpdateStreams
      def initialize(work_package:, filter:, since:, editing_journal_ids:, sorting:)
        @work_package = work_package
        @filter = filter
        @since = since
        @editing_journal_ids = editing_journal_ids
        @sorting = sorting
      end

      def emit_into(sink)
        rerender_changed(sink)
        rerender_renotified(sink)
        insert_latest(sink)

        if journals.present?
          remove_empty_state(sink)
          update_activity_counter(sink)
        end

        rerender_all_reactions(sink)
      end

      private

      attr_reader :work_package, :filter, :since, :editing_journal_ids, :sorting

      def journals
        @journals ||= begin
          scope = work_package.journals.internal_visible
          scope = scope.where.not(notes: "") if filter == Filters::ONLY_COMMENTS
          scope
        end
      end

      def grouped_emoji_reactions
        @grouped_emoji_reactions ||= EmojiReactions::GroupedQueries.grouped_emoji_reactions_by_reactable(
          reactable_id: journals.pluck(:id), reactable_type: "Journal"
        )
      end

      def whole_work_package_emoji_reactions
        @whole_work_package_emoji_reactions ||=
          EmojiReactions::GroupedQueries.grouped_work_package_journals_emoji_reactions_by_reactable(work_package)
      end

      def rerender_changed(sink)
        journals.where("updated_at > ?", since).find_each do |journal|
          next if editing?(journal.id)

          emit_item_show(sink, journal)
        end
      end

      def rerender_renotified(sink)
        journals.where(id: renotified_journal_ids).find_each do |journal|
          emit_item_show(sink, journal)
        end
      end

      def renotified_journal_ids
        Notification
          .where(journal_id: journals.select(:id))
          .where(recipient_id: User.current.id)
          .where("notifications.updated_at > ?", since)
          .where.not(journal_id: editing_journal_ids)
          .distinct
          .pluck(:journal_id)
      end

      def insert_latest(sink)
        journals.where("created_at > ?", since).find_each do |journal|
          sink.insert_via_turbo_stream(
            target_component: insert_target,
            component: Journals::ItemComponent.new(
              journal:, filter:, grouped_emoji_reactions: grouped_emoji_reactions.fetch(journal.id, {})
            ),
            action: sorting.asc? ? :append : :prepend
          )
        end
      end

      def rerender_all_reactions(sink)
        work_package.journals.each do |journal|
          sink.update_via_turbo_stream(
            component: Journals::ItemComponent::Reactions.new(
              journal:,
              grouped_emoji_reactions: whole_work_package_emoji_reactions[journal.id] || {}
            )
          )
        end
      end

      def remove_empty_state(sink)
        sink.remove_via_turbo_stream(component: Journals::EmptyComponent.new)
      end

      def update_activity_counter(sink)
        # update the activity counter in the primerized tabs, not the legacy tab
        sink.replace_via_turbo_stream(
          component: WorkPackages::Details::UpdateCounterComponent.new(work_package:, menu_name: "activity")
        )
      end

      def emit_item_show(sink, journal)
        sink.update_via_turbo_stream(
          component: Journals::ItemComponent.new(
            journal:, state: :show, filter:, grouped_emoji_reactions: grouped_emoji_reactions.fetch(journal.id, {})
          )
        )
      end

      def insert_target
        # only the component key matters here, so the journals/paginator are empty
        @insert_target ||= Journals::LazyIndexComponent.new(
          work_package:, journals: Journal.none, paginator: nil, filter:
        )
      end

      def editing?(journal_id)
        editing_journal_ids.include?(journal_id)
      end
    end
  end
end
