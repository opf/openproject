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

class OpenProject::JournalFormatter::MeetingState < JournalFormatter::Base
  def render(_key, values, options = { html: true })
    label_text = I18n.t(:label_meeting_state)
    label_text = content_tag(:strong, label_text) if options[:html]

    I18n.t(:text_journal_set_to, label: label_text, value: value(options[:html], values.last))
  end

  private

  def state_key(value)
    Meeting.states.key(value)
  end

  def value(html, state)
    html = html ? "_html" : ""

    I18n.t(:"label_meeting_state_#{state_key(state)}#{html}")
  end
end
