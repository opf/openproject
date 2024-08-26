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

module Meeting::Journalized
  extend ActiveSupport::Concern

  included do
    acts_as_journalized

    acts_as_event title: Proc.new { |o|
                           "#{I18n.t(:label_meeting)}: #{o.title} \
          #{format_date o.start_time} \
          #{format_time o.start_time, false}-#{format_time o.end_time, false})"
                         },
                  url: Proc.new { |o| { controller: "/meetings", action: "show", id: o } },
                  author: Proc.new(&:user),
                  description: ""

    register_journal_formatted_fields "title", "location", formatter_key: :plaintext
    register_journal_formatted_fields "duration", formatter_key: :fraction
    register_journal_formatted_fields "start_date", formatter_key: :datetime
    register_journal_formatted_fields "start_time", formatter_key: :meeting_start_time
    register_journal_formatted_fields "state", formatter_key: :meeting_state

    register_journal_formatted_fields "duration", formatter_key: :agenda_item_duration
    register_journal_formatted_fields /agenda_items_\d+_notes/, formatter_key: :agenda_item_diff
    register_journal_formatted_fields /agenda_items_\d+_title/, formatter_key: :agenda_item_title
    register_journal_formatted_fields /agenda_items_\d+_duration_in_minutes/, formatter_key: :agenda_item_duration
    register_journal_formatted_fields "position", formatter_key: :agenda_item_position
    register_journal_formatted_fields /agenda_items_\d+_work_package_id/, formatter_key: :meeting_work_package_id

    def touch_and_save_journals
      update_column(:updated_at, Time.current)
      save_journals
    end
  end
end
