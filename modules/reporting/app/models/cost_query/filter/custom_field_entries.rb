#-- copyright
# OpenProject Reporting Plugin
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

class CostQuery::Filter::CustomFieldEntries < Report::Filter::Base
  extend CostQuery::CustomFieldMixin

  on_prepare do
    applies_for :label_work_package_attributes
    # redmine internals just suck
    case custom_field.field_format
    when 'string', 'text' then use :string_operators
    when 'list'           then use :null_operators
    when 'date'           then use :time_operators
    when 'int', 'float'   then use :integer_operators
    when 'bool'
      @possible_values = [['true', 't'], ['false', 'f']]
      use :null_operators
    else
      fail "cannot handle #{custom_field.field_format.inspect}"
    end
  end

  def self.available_values(*)
    @possible_values || get_possible_values
  end

  def self.get_possible_values
    if custom_field.field_format == 'list'
      # Treat list CFs values as string options again, since
      # aggregation of groups are made by the values as well
      # and otherwise, it won't work as a filter.
      custom_field.possible_values.map { |co| [co.value, co.value] }
    else
      custom_field.possible_values
    end
  end
end
