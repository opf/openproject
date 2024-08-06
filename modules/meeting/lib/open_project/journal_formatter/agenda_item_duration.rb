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

class OpenProject::JournalFormatter::AgendaItemDuration < JournalFormatter::Base
  def render(key, values, options = { html: true })
    label_text = Meeting.human_attribute_name(:duration)
    label_text = content_tag(:strong, label_text) if options[:html]
    unit = key.to_s == "duration" ? :hours : :minutes

    mapped = values.map do |v|
      if v.blank?
        nil
      else
        ::OpenProject::Common::DurationComponent.new(v.to_f, unit, abbreviated: true).text
      end
    end

    value = value(options[:html], mapped.first, mapped.last)

    I18n.t(:text_journal_of, label: label_text, value:)
  end

  private

  def value(html, old_value, value)
    html = html ? "_html" : ""

    if old_value.nil?
      I18n.t(:"activity.item.meeting_agenda_item.duration.added#{html}", value:)
    elsif value.nil?
      I18n.t(:"activity.item.meeting_agenda_item.duration.removed")
    else
      I18n.t(:"activity.item.meeting_agenda_item.duration.updated#{html}", value:, old_value:)
    end
  end
end
