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

module SearchHelper
  def highlight_tokens(text, tokens)
    return text unless tokens && !tokens.empty?
    regexp = Regexp.new "(#{tokens.join('|')})", Regexp::IGNORECASE    
    result = ''
    text.split(regexp).each_with_index do |words, i|
      if result.length > 1200
        # maximum length of the preview reached
        result << '...'
        break
      end
      result << (i.even? ? h(words.length > 100 ? "#{words[0..44]} ... #{words[-45..-1]}" : words) : content_tag('span', h(words), :class => 'highlight'))
    end
    result
  end
end
