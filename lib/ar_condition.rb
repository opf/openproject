# redMine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
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

class ARCondition
  attr_reader :conditions
  
  def initialize(condition=nil)
    @conditions = ['1=1']
    @conditions.add(condition) if condition
  end
  
  def add(condition)
    if condition.is_a?(Array)
      @conditions.first << " AND (#{condition.first})"
      @conditions += condition[1..-1]
    elsif condition.is_a?(String)
      @conditions.first << " AND (#{condition})"
    else
      raise "Unsupported #{condition.class} condition: #{condition}"
    end
    self
  end

  def <<(condition)
    add(condition)
  end
end
