# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
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
      
      s << "<option #{attrs}>#{indent}#{h page.pretty_title}</option>\n" + 
             wiki_page_options_for_select(pages, selected, page, level + 1)
    end
    s
  end
end
