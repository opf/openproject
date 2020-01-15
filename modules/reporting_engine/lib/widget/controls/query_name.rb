#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Widget::Controls::QueryName < Widget::Controls
  dont_cache! # The name might change, but the query stays the same...

  def render
    options = { id: 'query_saved_name', 'data-translations' => translations }
    if @subject.new_record?
      name = l(:label_new_report)
      icon = ''
    else
      name = @subject.name
      options['data-is_public'] = @subject.public?
      options['data-is_new'] = @subject.new_record?
    end
    write(content_tag(:span, h(name), options) + icon.to_s)
  end

  def translations
    { isPublic: l(:field_is_public) }.to_json
  end
end
