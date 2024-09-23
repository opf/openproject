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

class Activities::MeetingEventMapper < Activities::EventMapper
  include ActionView::Helpers::TagHelper
  include OpenProject::StaticRouting::UrlHelpers
  include ActionView::Helpers::UrlHelper

  protected

  def map_to_event(journal)
    agenda_changes = agenda_changes(journal)
    count = agenda_changes.count
    total = journal.details.count

    if count > 0 && count < total
      # If we have a mix of meeting and agenda item journal, split it up
      split_agenda_event(journal, agenda_changes)
    elsif count == total
      # All changes are related to agenda items, convert it to an agenda event
      create_agenda_events(journal, agenda_changes)
    else
      create_meeting_event(journal)
    end
  end

  ##
  # We want to split journals into multiple events
  # if they contain meeting AND agenda item changes.
  def split_agenda_event(journal, agenda_changes)
    agenda_event = create_agenda_events(journal, agenda_changes)

    # Create an agenda event
    unless only_agenda_item_changes?(journal)
      meeting_event = create_meeting_event(journal)
      agenda_event << meeting_event if meeting_event
    end

    agenda_event
  end

  def create_meeting_event(journal)
    params = meeting_params(journal)
    return if params[:data][:details].empty?

    create_event(params)
  end

  def create_agenda_events(journal, agenda_changes)
    params = mapped_params(journal)

    agenda_changes.map do |agenda_item_id, changes|
      work_package = named_change(changes, "work_package_id")

      params[:data] = {
        id: agenda_item_id,
        details: changes,
        initial: initial_change?(changes),
        deleted: deleted_change?(changes),
        work_package:
      }

      params[:event_title] = agenda_item_title(journal, agenda_item_id, changes)
      params[:event_type] = :agenda_item

      create_event(params)
    end
  end

  def initial_change?(changes)
    title_change = named_change(changes, "title")
    work_package_change = named_change(changes, "work_package_id")

    (title_change && title_change.first.nil?) || (work_package_change && work_package_change.first.nil?)
  end

  def deleted_change?(changes)
    title_change = named_change(changes, "title")
    work_package_change = named_change(changes, "work_package_id")

    if work_package_change
      work_package_change.last.nil?
    elsif title_change
      title_change.last.nil?
    else
      false
    end
  end

  def agenda_item_title(journal, id, details)
    agenda_journal = journal.agenda_item_journals.detect { |j| j.agenda_item_id == id }
    work_package_change = named_change(details, "work_package_id")

    if agenda_journal&.item_type == "work_package"
      work_package_title(agenda_journal.work_package_id)
    elsif work_package_change
      work_package_title(work_package_change.first)
    else
      title = agenda_journal&.title || named_change(details, "title")&.compact&.last
      title.nil? ? I18n.t(:text_deleted_agenda_item) : I18n.t("text_agenda_item_title", title:)
    end
  end

  def named_change(changes, key)
    changes.detect { |k, _| k.to_s.include?(key) }&.last
  end

  def work_package_title(work_package_id)
    if work_package_id.nil?
      I18n.t(:text_agenda_work_package_deleted)
    elsif (work_package = WorkPackage.visible.find_by(id: work_package_id))
      link_to(work_package.to_s, url_helpers.work_package_path(work_package))
    else
      I18n.t(:label_agenda_item_undisclosed_wp, id: work_package_id)
    end
  end

  def agenda_changes(journal)
    journal
      .details
      .select { |key, _| key.start_with?("agenda_items_") }
      .reject { |key, _| key.end_with?("_position") }
      .each_with_object(Hash.new { |h, k| h[k] = {} }) do |(key, values), changes|
      id, = key.gsub("agenda_items_", "").split("_", 2)
      changes[id.to_i][key.to_sym] = values
    end
  end

  def only_agenda_item_changes?(journal)
    journal.details.all? { |key, _| key.start_with?("agenda_items_") } &&
      !journal.details.all? { |key, _| key.end_with?("_position") }
  end

  def event_data(journal)
    {
      meeting_title: journal.data.title,
      meeting_start_time: start_time(journal.data.start_time),
      meeting_duration: journal.data.duration
    }
  end

  def meeting_params(journal)
    mapped_params(journal)
      .merge(
        {
          event_title: journal.initial? ? I18n.t(:label_initial_meeting_details) : I18n.t(:label_meeting_details),
          data: {
            details: filtered_meeting_details(journal.details)
          }
        }
      )
  end

  def filtered_meeting_details(details)
    details
      .reject { |key, _| key.start_with?("agenda_items_") && !key.end_with?("_position") }
      .reject { |key, value| key.end_with?("_position") && value.first.nil? }
      .each_with_object({}) do |(key, value), hash|
      if key =~ /agenda_items_(\d+)_position/
        hash[:position] ||= {}
        hash[:position][Regexp.last_match(1).to_i] = value
      else
        hash[key.to_sym] = value
      end
    end
  end

  def start_time(journal_time)
    if journal_time.is_a?(String)
      DateTime.parse(journal_time)
    else
      journal_time
    end
  end

  # duplicates necessary behaviour from Activites::Fetcher
  def event_title(_journal, data)
    start_time = data[:meeting_start_time]
    end_time = start_time + data[:meeting_duration].to_f.hours

    fstart_with = format_date start_time
    fstart_without = format_time start_time, false
    fend_without = format_time end_time, false

    "#{I18n.t(:label_meeting)}: #{data[:meeting_title]} (#{fstart_with} #{fstart_without}-#{fend_without})"
  end

  def journals_includes
    super + %i[agenda_item_journals]
  end

  def url_helpers
    @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
  end
end
