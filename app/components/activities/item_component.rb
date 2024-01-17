# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Activities::ItemComponent < ViewComponent::Base
  with_collection_parameter :event
  strip_trailing_whitespace

  def initialize(event:, current_project: nil, display_user: true, activity_page: nil)
    super()
    @event = event
    @current_project = current_project
    @display_user = display_user
    @activity_page = activity_page
  end

  def project_suffix
    return if activity?(Project)
    return if activity_is_from_current_project?

    kind = activity_is_from_subproject? ? 'subproject' : 'project'
    suffix = I18n.t("events.title.#{kind}", name: link_to(@event.project.name, @event.project))
    "(#{suffix})".html_safe # rubocop:disable Rails/OutputSafety
  end

  def display_user?
    @display_user
  end

  def display_details?
    return false if @event.journal.initial? && @event.journal.journable_type != 'TimeEntry'

    rendered_details.present?
  end

  def rendered_details
    filter_details.filter_map { |detail| @event.journal.render_detail(detail, activity_page: @activity_page) }
  end

  def comment
    return unless activity?(WorkPackage)

    @event.event_description
  end

  def description
    return if activity?(WorkPackage) || activity?(TimeEntry)

    @event.event_description
  end

  def time_entry_url
    return unless activity?(TimeEntry)

    @event.event_url
  end

  private

  def activity?(type)
    @event.journal.journable_type == type.to_s
  end

  def activity_is_from_current_project?
    @current_project && (@event.project == @current_project)
  end

  def activity_is_from_subproject?
    @current_project && (@event.project != @current_project)
  end

  def filter_details
    details = @event.journal.details

    details.delete(:user_id) if details[:logged_by_id] == details[:user_id]
    delete_detail(details, :work_package_id)
    delete_detail(details, :comments)
    delete_detail(details, :activity_id)
    delete_detail(details, :spent_on)

    details
  end

  def delete_detail(details, field)
    details.delete(field) if details[field] && details[field].first.nil?
  end
end
