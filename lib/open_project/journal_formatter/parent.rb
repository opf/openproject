#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

# Need to fix rubocop issues

class OpenProject::JournalFormatter::Parent < JournalFormatter::Base
  def render(_key, values, options = { html: true })

    projects = Project.find(values).sort! { |a, b| values.index(a.id) <=> values.index(b.id) }
    label_text = options[:html] ? content_tag('strong', "Parent") : "Parent"
    if values.first.nil?
      activated_text = options[:html] ? "set to #{content_tag('i', projects.last.name)}"
                                      : "set to #{projects.last.name}"
    else
      activated_text = options[:html] ? "changed from #{content_tag('i', projects.first.name)} " \
                                      "to #{content_tag('i', projects.last.name)}"
                                      : "changed from #{projects.first.name} to #{projects.last.name}"
    end

    I18n.t(:text_journal_label_value, label: label_text, value: activated_text)
  end
end
