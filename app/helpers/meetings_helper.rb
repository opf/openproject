#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

module MeetingsHelper
  def format_participant_list(participants)
    participants.sort.map { |p| link_to_user p.user }.join('; ').html_safe
  end

  def render_meeting_journal(model, journal, options = {})
    return '' if journal.initial?
    journal_content = render_journal_details(journal, :label_updated_time_by, model, options)
    content_tag 'div', journal_content,  id: "change-#{journal.id}", class: 'journal'
  end
end
