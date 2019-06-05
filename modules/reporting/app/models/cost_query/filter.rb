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

class CostQuery::Filter < Report::Filter
  def self.all
    @all ||= super + Set[
      CostQuery::Filter::ActivityId,
       CostQuery::Filter::AssignedToId,
       CostQuery::Filter::AuthorId,
       CostQuery::Filter::CategoryId,
       CostQuery::Filter::CostTypeId,
       CostQuery::Filter::CreatedOn,
       CostQuery::Filter::DueDate,
       CostQuery::Filter::FixedVersionId,
       CostQuery::Filter::WorkPackageId,
       CostQuery::Filter::OverriddenCosts,
       CostQuery::Filter::PriorityId,
       CostQuery::Filter::ProjectId,
       CostQuery::Filter::SpentOn,
       CostQuery::Filter::StartDate,
       CostQuery::Filter::StatusId,
       CostQuery::Filter::Subject,
       CostQuery::Filter::TypeId,
       CostQuery::Filter::UpdatedOn,
       CostQuery::Filter::UserId,
       CostQuery::Filter::PermissionFilter,
      *CostQuery::Filter::CustomFieldEntries.all
    ]
  end
end
