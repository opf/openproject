#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module MessageAccessibilityHelper
  def accessible_time_select(object_name, method, options = {}, html_options = {})
    labels = ''
    select = time_select(object_name, method, options, html_options)

    select_ids = select.scan(/<select id="(?<select_id>\w+)"/)
    ids_with_label = select_ids.zip([:label_meeting_hour, :label_meeting_minute])

    ids_with_label.each do |iwl|
      labels += content_tag(:label, l(iwl[1]), for: iwl[0], class: 'hidden-for-sighted')
    end

    (labels + select).html_safe
  end
end
