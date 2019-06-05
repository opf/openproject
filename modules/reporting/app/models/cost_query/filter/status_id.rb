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

# we have to require this here because the operators would not be defined otherwise
require_dependency 'cost_query/operator'
class CostQuery::Filter::StatusId < Report::Filter::Base
  available_operators 'c', 'o'
  join_table WorkPackage, Status => [WorkPackage, :status]
  applies_for :label_work_package_attributes

  def self.label
    WorkPackage.human_attribute_name(:status)
  end

  def self.available_values(*)
    Status.order(Arel.sql('name')).pluck(:name, :id)
  end
end
