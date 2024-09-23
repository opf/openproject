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

class OpenProject::JournalFormatter::MeetingWorkPackageId < JournalFormatter::Base
  def render(_key, values, options = { html: true })
    label_text = I18n.t(:label_agenda_item_work_package)
    label_text = content_tag(:strong, label_text) if options[:html]

    I18n.t(:text_journal_of, label: label_text, value: value(options[:html], values))
  end

  private

  def value(html, values)
    html = html ? "_html" : ""

    new = visible(values.last)
    old = visible(values.first)

    I18n.t(:"activity.item.meeting_agenda_item.work_package.updated#{html}",
           value: new ? new.name : I18n.t(:label_agenda_item_undisclosed_wp, id: values.last),
           old_value: old ? old.name : I18n.t(:label_agenda_item_undisclosed_wp, id: values.first))
  end

  def visible(work_package_id)
    WorkPackage.visible.find_by(id: work_package_id)
  end
end
