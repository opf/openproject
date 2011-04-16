# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

module GanttHelper

  def gantt_zoom_link(gantt, in_or_out)
    case in_or_out
    when :in
      if gantt.zoom < 4
        link_to_content_update l(:text_zoom_in),
          params.merge(gantt.params.merge(:zoom => (gantt.zoom+1))),
          :class => 'icon icon-zoom-in'
      else
        content_tag('span', l(:text_zoom_in), :class => 'icon icon-zoom-in')
      end
      
    when :out
      if gantt.zoom > 1
        link_to_content_update l(:text_zoom_out),
          params.merge(gantt.params.merge(:zoom => (gantt.zoom-1))),
          :class => 'icon icon-zoom-out'
      else
        content_tag('span', l(:text_zoom_out), :class => 'icon icon-zoom-out')
      end
    end
  end
end
