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

class MeetingAgendaItem::Slides
  include OpenProject::TextFormatting

  def initialize(meeting_agenda_item)
    @meeting_agenda_item = meeting_agenda_item
  end

  def count
    contents.size
  end

  def clamp(number)
    number.to_i.clamp(1, count)
  end

  def content(number)
    contents[clamp(number) - 1]
  end

  private

  def contents
    @contents ||= split(format_text(@meeting_agenda_item, :notes)).presence || ["".html_safe]
  end

  def split(html)
    Nokogiri::HTML.fragment(html)
      .children
      .to_a
      .split { |node| node.element? && node.name == "hr" }
      .map { |nodes| nodes.map(&:to_html).join }
      .compact_blank
      .map(&:html_safe)
  end
end
