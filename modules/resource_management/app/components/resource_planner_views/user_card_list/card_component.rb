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

module ResourcePlannerViews::UserCardList
  # Modelled on +Users::HoverCardComponent+, but kept as its own component
  # so the card can evolve independently of the hover card
  # TODO - OP-19586: match card layout to spec
  class CardComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(user:, details_path:, remove_path: nil, utilization: nil)
      super

      @user = user
      @details_path = details_path
      @remove_path = remove_path
      @utilization = utilization
    end

    def render?
      @user&.visible?(User.current)
    end

    def show_email?
      (@user == User.current) || User.current.allowed_globally?(:view_user_email)
    end

    def utilization?
      !@utilization.nil?
    end

    def utilization_label
      helpers.number_to_percentage(@utilization, precision: 0)
    end

    # Constructs a string in the form of:
    # "Member of group4, group5"
    # or
    # "Member of group1, group2 and 3 more"
    # The latter string is cut off since the complete list of group names would exceed the allowed `max_length`.
    def group_membership_summary(max_length = 40)
      groups = @user.groups.visible.order(:lastname)
      return no_group_text if groups.empty?

      group_links = linked_group_names(groups)

      cutoff_index = calculate_cutoff_index(groups.map(&:name), max_length)
      build_summary(group_links, cutoff_index)
    end

    private

    def linked_group_names(groups)
      groups.map { |group| link_to(h(group.name), show_group_path(group)) }
    end

    def no_group_text
      t("users.groups.no_results_title_text")
    end

    # Calculate the index at which to cut off the group names, based on plain text length
    def calculate_cutoff_index(names, max_length)
      current_length = 0

      names.each_with_index do |name, index|
        new_length = current_length + name.length + (index > 0 ? 2 : 0) # 2 for ", " separator
        return index if new_length > max_length

        current_length = new_length
      end

      names.size # No cutoff needed -> return the total size
    end

    def build_summary(links, cutoff_index)
      summary_links = safe_join(links[0...cutoff_index], ", ")
      remaining_count = links.size - cutoff_index
      remaining_count_link = link_to(t("users.groups.more", count: remaining_count), user_path(@user))

      if remaining_count > 0
        t("users.groups.summary_with_more_html", names: summary_links, count_link: remaining_count_link)
      else
        t("users.groups.summary_html", names: summary_links)
      end
    end

    def card_options
      {
        classes: "op-user-card",
        test_selector: "op-user-card",
        data: {
          controller: "resource-management--user-card",
          "resource-management--user-card-url-value": @details_path
        }
      }
    end
  end
end
