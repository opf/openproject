#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# See doc/COPYRIGHT.rdoc for more details.
#++

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
