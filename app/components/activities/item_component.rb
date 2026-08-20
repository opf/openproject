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

    kind = activity_is_from_subproject? ? "subproject" : "project"
    helpers.t("events.title.#{kind}_html", name: link_to(@event.project.name, @event.project))
  end

  def display_user?
    @display_user
  end

  def display_details?
    journal = @event.journal
    return false if (initial? && journal.journable_type != "TimeEntry") || deletion?

    rendered_details.present?
  end

  def noop?
    !initial? && !deletion? && @event.journal.noop?
  end

  def rendered_details
    if data[:details]
      render_event_details
    else
      # this doesn't do anything for details of type "agenda_items_10_title"
      filter_journal_details.filter_map { |detail| @event.journal.render_detail(detail, activity_page: @activity_page) }
    end
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

  def initial?
    @event.journal.initial? || data[:initial]
  end

  def deletion?
    data[:deleted]
  end

  def work_package?
    data.key?(:work_package) || data[:entity_type] == "WorkPackage"
  end

  def data
    @event.data || {}
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

  def filter_journal_details
    details = @event.journal.details

    details.delete(:user_id) if details[:logged_by_id] == details[:user_id]
    remove_detail_when_changing_from_empty(details, "work_package_id")
    remove_detail_when_changing_from_empty(details, "entity_type")
    remove_detail_when_changing_from_empty(details, "entity_id")
    remove_detail_when_changing_from_empty(details, "comments")
    remove_detail_when_changing_from_empty(details, "activity_id")
    remove_detail_when_changing_from_empty(details, "spent_on")

    build_polymorphic_entity_gid_changeset(details)

    details
  end

  def build_polymorphic_entity_gid_changeset(details)
    return if !details.key?("entity_id") && !details.key?("entity_type")

    details["entity_gid"] = [
      build_gid(*type_and_id_for(details, "entity", index: 0)),
      build_gid(*type_and_id_for(details, "entity", index: 1))
    ]

    details.delete("entity_id")
    details.delete("entity_type")
  end

  def type_and_id_for(details, field, index:)
    [
      details["#{field}_type"]&.at(index) || @event.journal.journable.public_send("#{field}_type"),
      details["#{field}_id"]&.at(index) || @event.journal.journable.public_send("#{field}_id")
    ]
  end

  def remove_detail_when_changing_from_empty(details, field)
    details.delete(field) if details[field] && details[field].first.nil?
  end

  def build_gid(entity_type, entity_id)
    "gid://#{GlobalID.app}/#{entity_type}/#{entity_id}"
  end

  def render_event_details
    data[:details].filter_map do |detail|
      @event.journal.render_detail(detail, activity_page: @activity_page)
    end
  end
end
