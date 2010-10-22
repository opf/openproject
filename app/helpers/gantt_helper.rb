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
    img_attributes = {:style => 'height:1.4em; width:1.4em; margin-left: 3px;'} # em for accessibility

    case in_or_out
    when :in
      if gantt.zoom < 4
        link_to_remote(l(:text_zoom_in) + image_tag('zoom_in.png', img_attributes.merge(:alt => l(:text_zoom_in))),
                       {:url => gantt.params.merge(:zoom => (gantt.zoom+1)), :method => :get, :update => 'content'},
                       {:href => url_for(gantt.params.merge(:zoom => (gantt.zoom+1)))})
      else
        l(:text_zoom_in) +
          image_tag('zoom_in_g.png', img_attributes.merge(:alt => l(:text_zoom_in)))
      end
      
    when :out
      if gantt.zoom > 1
        link_to_remote(l(:text_zoom_out) + image_tag('zoom_out.png', img_attributes.merge(:alt => l(:text_zoom_out))),
                       {:url => gantt.params.merge(:zoom => (gantt.zoom-1)), :method => :get, :update => 'content'},
                       {:href => url_for(gantt.params.merge(:zoom => (gantt.zoom-1)))})
      else
        l(:text_zoom_out) +
          image_tag('zoom_out_g.png', img_attributes.merge(:alt => l(:text_zoom_out)))
      end
    end
  end
  
  def number_of_issues_on_versions(gantt)
    versions = gantt.events.collect {|event| (event.is_a? Version) ? event : nil}.compact

    versions.sum {|v| v.fixed_issues.for_gantt.with_query(@query).count}
  end
end
