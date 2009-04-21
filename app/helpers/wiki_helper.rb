# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

module WikiHelper
  
  def wiki_page_options_for_select(pages, selected = nil, parent = nil, level = 0)
    s = ''
    pages.select {|p| p.parent == parent}.each do |page|
      attrs = "value='#{page.id}'"
      attrs << " selected='selected'" if selected == page
      indent = (level > 0) ? ('&nbsp;' * level * 2 + '&#187; ') : nil
      
      s << "<option value='#{page.id}'>#{indent}#{h page.pretty_title}</option>\n" + 
             wiki_page_options_for_select(pages, selected, page, level + 1)
    end
    s
  end
  
  def html_diff(wdiff)
    words = wdiff.words.collect{|word| h(word)}
    words_add = 0
    words_del = 0
    dels = 0
    del_off = 0
    wdiff.diff.diffs.each do |diff|
      add_at = nil
      add_to = nil
      del_at = nil
      deleted = ""	    
      diff.each do |change|
        pos = change[1]
        if change[0] == "+"
          add_at = pos + dels unless add_at
          add_to = pos + dels
          words_add += 1
        else
          del_at = pos unless del_at
          deleted << ' ' + change[2]
          words_del	 += 1
        end
      end
      if add_at
        words[add_at] = '<span class="diff_in">' + words[add_at]
        words[add_to] = words[add_to] + '</span>'
      end
      if del_at
        words.insert del_at - del_off + dels + words_add, '<span class="diff_out">' + deleted + '</span>'
        dels += 1
        del_off += words_del
        words_del = 0
      end
    end
    simple_format_without_paragraph(words.join(' '))
  end
end
