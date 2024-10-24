#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
      class ItemComponent::Reactions < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(journal:, grouped_emoji_reactions:)
          super

          @journal = journal
          @grouped_emoji_reactions = grouped_emoji_reactions
        end

        def render?
          grouped_emoji_reactions.present?
        end

        private

        attr_reader :journal, :grouped_emoji_reactions

        def wrapper_uniq_by = journal.id
        def work_package = journal.journable

        def counter_color(users)
          reacted_by_current_user?(users) ? :accent : nil
        end

        def button_scheme(users)
          reacted_by_current_user?(users) ? :default : :invisible
        end

        def reacted_by_current_user?(users)
          users.any? { |u| u[:id] == User.current.id }
        end

        # ARIA-label, show names and emoji type: "{Name of reaction} by {user A}, {user B} and {user C}".
        def aria_label_text(reaction, users)
          "#{I18n.t('reactions.reaction_by', reaction: reaction.to_s.tr('_', ' '))} #{number_of_user_reactions_text(users)}"
        end

        # Visually, show just names: "{user A}, {user B} and {user C}"
        def number_of_user_reactions_text(users, max_displayed_users_count: 5)
          user_count = users.length
          displayed_users = users.take(max_displayed_users_count).pluck(:name)

          return displayed_users.first if user_count == 1

          if user_count <= max_displayed_users_count
            "#{displayed_users[0..-2].join(', ')} #{I18n.t('reactions.and_user', user: displayed_users.last)}"
          elsif user_count == max_displayed_users_count + 1
            "#{displayed_users.join(', ')} #{I18n.t('reactions.and_n_others_singular', n: 1)}"
          else
            "#{displayed_users.join(', ')} #{I18n.t('reactions.and_n_others_plural',
                                                    n: user_count - max_displayed_users_count)}"
          end
        end

        def href(reaction:)
          return if current_user_cannot_react?

          toggle_reaction_work_package_activity_path(journal.journable.id, id: journal.id, reaction:)
        end

        def current_user_can_react?
          User.current.allowed_in_work_package?(:add_work_package_notes, work_package)
        end

        def current_user_cannot_react? = !current_user_can_react?
      end
    end
  end
end
