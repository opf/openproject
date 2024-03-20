#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class Wikis::Annotate
  attr_reader :lines, :content

  def initialize(content)
    @content = content
    current = content
    current_lines = current.data.text.split(/\r?\n/)
    @lines = current_lines.map { |t| [nil, nil, t] }
    positions = []
    current_lines.size.times { |i| positions << i }
    while current.previous
      d = current.previous.data.text.split(/\r?\n/).diff(current.data.text.split(/\r?\n/)).diffs.flatten
      d.each_slice(3) do |s|
        sign = s[0]
        line = s[1]
        if sign == '+' && positions[line] && positions[line] != -1 && @lines[positions[line]][0].nil?
          @lines[positions[line]][0] = current.version
          @lines[positions[line]][1] = current.data.author
        end
      end
      d.each_slice(3) do |s|
        sign = s[0]
        line = s[1]
        if sign == '-'
          positions.insert(line, -1)
        else
          positions[line] = nil
        end
      end
      positions.compact!
      # Stop if every line is annotated
      break unless @lines.detect { |line| line[0].nil? }

      current = current.previous
    end
    @lines.each { |line| line[0] ||= current.version }
  end
end
