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
    # Streams the activity a polling client has missed: it decides which journals
    # changed since the client last polled and renders each as the right turbo-stream
    # mutation. Mixed into the controller so it reuses the existing item-rendering and
    # reaction-grouping helpers and emits through OpTurbo directly.
    module UpdateStreaming
      extend ActiveSupport::Concern

      private

      def stream_journal_updates_since(since, editing_journal_ids)
        rerender_changed_journals(since, editing_journal_ids)
        rerender_renotified_journals(since, editing_journal_ids)
        insert_journals_created_after(since)

        if streamed_journals.present?
          remove_streamed_empty_state
          update_activity_counter
        end

        rerender_all_journal_reactions
      end

      def streamed_journals
        @streamed_journals ||= begin
          scope = @work_package.journals.internal_visible
          scope = scope.where.not(notes: "") if @filter == Filters::ONLY_COMMENTS
          scope
        end
      end

      def streamed_grouped_emoji_reactions
        @streamed_grouped_emoji_reactions ||= grouped_emoji_reactions_for(streamed_journals.pluck(:id))
      end

      def rerender_changed_journals(since, editing_journal_ids)
        streamed_journals.where("updated_at > ?", since).find_each do |journal|
          next if editing_journal_ids.include?(journal.id)

          rerender_journal_show(journal)
        end
      end

      def rerender_renotified_journals(since, editing_journal_ids)
        Notification
          .where(journal_id: streamed_journals.pluck(:id))
          .where(recipient_id: User.current.id)
          .where("notifications.updated_at > ?", since)
          .find_each do |notification|
            next if editing_journal_ids.include?(notification.journal_id)

            rerender_journal_show(streamed_journals.find(notification.journal_id))
          end
      end

      def rerender_journal_show(journal)
        update_item_show_component(
          journal:, grouped_emoji_reactions: streamed_grouped_emoji_reactions.fetch(journal.id, {})
        )
      end

      def insert_journals_created_after(since)
        streamed_journals.where("created_at > ?", since).find_each do |journal|
          insert_via_turbo_stream(
            target_component: streamed_insert_target,
            component: Journals::ItemComponent.new(
              journal:,
              filter: @filter,
              grouped_emoji_reactions: streamed_grouped_emoji_reactions.fetch(journal.id, {})
            ),
            action: journal_sorting.asc? ? :append : :prepend
          )
        end
      end

      def rerender_all_journal_reactions
        @work_package.journals.each do |journal|
          update_via_turbo_stream(
            component: Journals::ItemComponent::Reactions.new(
              journal:,
              grouped_emoji_reactions: wp_journals_emoji_reactions[journal.id] || {}
            )
          )
        end
      end

      def remove_streamed_empty_state
        remove_via_turbo_stream(component: Journals::EmptyComponent.new)
      end

      def update_activity_counter
        # update the activity counter in the primerized tabs, not the legacy tab
        replace_via_turbo_stream(
          component: WorkPackages::Details::UpdateCounterComponent.new(work_package: @work_package, menu_name: "activity")
        )
      end

      def streamed_insert_target
        # only the component key matters here, so the journals/paginator are empty
        @streamed_insert_target ||= Journals::LazyIndexComponent.new(
          work_package: @work_package, journals: Journal.none, paginator: nil, filter: @filter
        )
      end
    end
  end
end
