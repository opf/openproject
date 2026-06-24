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

class Users::HoverCardComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  MULTI_VALUE_DISPLAY_LIMIT = 3

  def initialize(id:)
    super

    @user = User.visible.find_by(id:)
  end

  def render?
    @user&.visible?(User.current)
  end

  def show_email?
    (@user == User.current) || User.current.allowed_globally?(:view_user_email)
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

  def card_sections_with_fields
    @card_sections_with_fields ||= UserCustomFieldSection.with_filled_fields_for(@user, visible_on_user_card: true)
  end

  private

  # Renders the values of a multi-value field as a row of Primer labels,
  # capped at MULTI_VALUE_DISPLAY_LIMIT with an "and N more" overflow hint.
  def render_value_labels(value)
    values = Array(value)
    remaining = values.size - MULTI_VALUE_DISPLAY_LIMIT

    labels = values.first(MULTI_VALUE_DISPLAY_LIMIT).map do |item|
      render(Primer::Beta::Label.new(scheme: :accent, mr: 1)) { item }
    end

    if remaining > 0
      labels << render(Primer::Beta::Text.new) do
        t("custom_fields.multi_value_more", count: remaining)
      end
    end

    safe_join(labels, " ")
  end

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
end
