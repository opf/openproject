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

class Widget::Controls::Save < Widget::Controls
  def render
    return '' if @subject.new_record? or !@options[:can_save]
    write link_to(l(:button_save),
                  '#',
                  id: 'query-breadcrumb-save',
                  class: 'button icon-context icon-save',
                  :"data-target" => url_for(action: 'update', id: @subject.id, set_filter: '1'))
  end
end
