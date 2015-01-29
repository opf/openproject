#-- copyright
# ReportingEngine
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
