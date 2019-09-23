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

require "set"

class CostQuery::GroupBy < Report::GroupBy
  def self.all
    @all ||= super + Set[
      CostQuery::GroupBy::ActivityId,
      CostQuery::GroupBy::CostObjectId,
      CostQuery::GroupBy::CostTypeId,
      CostQuery::GroupBy::FixedVersionId,
      CostQuery::GroupBy::WorkPackageId,
      CostQuery::GroupBy::PriorityId,
      CostQuery::GroupBy::ProjectId,
      CostQuery::GroupBy::SpentOn,
      CostQuery::GroupBy::SingletonValue,
      CostQuery::GroupBy::Tmonth,
      CostQuery::GroupBy::TypeId,
      CostQuery::GroupBy::Tyear,
      CostQuery::GroupBy::UserId,
      CostQuery::GroupBy::Week,
      CostQuery::GroupBy::AuthorId,
      CostQuery::GroupBy::AssignedToId,
      CostQuery::GroupBy::CategoryId,
      CostQuery::GroupBy::StatusId,
      *CostQuery::GroupBy::CustomFieldEntries.all
    ]
  end
end
