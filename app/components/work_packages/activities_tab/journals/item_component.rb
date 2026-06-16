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
    module Journals
      class ItemComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable
        include WorkPackages::ActivitiesTab::SharedHelpers
        include WorkPackages::ActivitiesTab::StimulusControllers

        def initialize(journal:, filter:, grouped_emoji_reactions:, state: :show)
          super

          @journal = journal
          @filter = filter
          @grouped_emoji_reactions = grouped_emoji_reactions
          @state = state
        end

        private

        attr_reader :journal, :state, :filter, :grouped_emoji_reactions

        def menu_id
          ItemComponent::Actions.menu_id(journal)
        end

        def wrapper_uniq_by
          journal.id
        end

        def wrapper_data_attributes
          {
            controller: "work-packages--activities-tab--item",
            "work-packages--activities-tab--item-activity-url-value": activity_url(journal)
          }
        end

        def container_classes
          [].tap do |classes|
            if journal.internal?
              classes << "work-packages-activities-tab-journals-item-component--container__internal-comment"
            end
          end
        end

        def comment_header_classes
          [].tap do |classes|
            if journal.internal?
              classes << "work-packages-activities-tab-journals-item-component--header__internal-comment"
            end
          end
        end

        def comment_body_classes
          ["work-packages-activities-tab-journals-item-component--journal-notes-body"].tap do |classes|
            if journal.internal?
              classes << "work-packages-activities-tab-journals-item-component--journal-notes-body__internal-comment"
            end
          end
        end

        def show_comment_container?
          (journal.notes.present? || noop?) && filter != Filters::ONLY_CHANGES
        end

        def noop?
          journal.noop?
        end

        def updated?
          return false if journal.initial?

          journal.updated_at - journal.created_at > 5.seconds
        end

        def has_unread_notifications?
          journal.has_unread_notifications_for_user?(User.current)
        end

        def notification_on_details?
          has_unread_notifications? && journal.notes.blank?
        end
      end
    end
  end
end
