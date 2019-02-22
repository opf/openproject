#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
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

module CostlogHelper
  include TimelogHelper

  def cost_types_collection_for_select_options(selected_type = nil)
    cost_types = CostType.active.sort

    if selected_type && !cost_types.include?(selected_type)
      cost_types << selected_type
      cost_types.sort
    end
    cost_types.map { |t| [t.name, t.id] }
  end

  def user_collection_for_select_options(_options = {})
    users = @project.possible_assignees
    users.map { |t| [t.name, t.id] }
  end

  def extended_progress_bar(pcts, options = {})
    return progress_bar(pcts, options) unless pcts.is_a?(Numeric) && pcts > 100

    closed = ((100.0 / pcts) * 100).round
    done = 100.0 - ((100.0 / pcts) * 100).round
    progress_bar([closed, done], options)
  end

  def clean_currency(value)
    return nil if value.nil? || value == ''

    value = value.strip
    value.gsub!(t(:currency_delimiter), '') if value.include?(t(:currency_delimiter)) && value.include?(t(:currency_separator))
    value.gsub(',', '.')
    BigDecimal.new(value)
  end

  def to_currency_with_empty(rate)
    rate.nil? ?
      '0.0' :
      number_to_currency(rate.rate)
  end
end
