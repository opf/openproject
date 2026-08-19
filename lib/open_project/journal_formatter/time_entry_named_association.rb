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

class OpenProject::JournalFormatter::TimeEntryNamedAssociation < JournalFormatter::NamedAssociation
  private

  def format_details(key, values, cache:)
    label = I18n.t("activity.item.time_entry.logged_for")

    old_value, value = *format_values(values, key, cache:)

    [label, old_value, value]
  end

  def format_html_details(label, old_value, value)
    label = content_tag(:strong, label)

    [label, old_value, value]
  end

  def render_ternary_detail_text(label, value, _old_value, _options)
    I18n.t(:text_journal_of, label:, value:)
  end
end
