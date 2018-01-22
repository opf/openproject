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

class CostQuery::Filter::CostTypeId < Report::Filter::Base
  extra_options :display
  selectable false

  def self.label
    WorkPackage.human_attribute_name(:cost_type)
  end

  def initialize(child = nil, options = {})
    super
    @display = options[:display]
  end

  ##
  # @Override
  # Displayability is decided on the instance
  def display?
    return super if @display.nil?
    @display
  end

  def field
    # prevent setting an extra cost type constraint
    # WHERE cost_type_id IN (...)
    # when money value is requested
    if values == ["0"]
      []
    else
      super
    end
  end

  def self.available_values(*)
    [[::I18n.t(:caption_labor), -1]] + CostType.order('name').pluck(:name, :id)
  end
end
