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

class CostReportsMigration < ActiveRecord::Migration[5.0]

  class CostQuery < ActiveRecord::Base
    serialize :serialized, Hash
  end

  def up
    migrate_cost_queries({ "TrackerId"     => "TypeId",
                           "IssueId"       => "WorkPackageId" })
  end

  def down
    migrate_cost_queries({ "TypeId"        => "TrackerId",
                           "WorkPackageId" =>  "IssueId"      })
  end

  private

  def migrate_cost_queries(mapping)
    CostQuery.find_each do |cost_query|
      query = cost_query.serialized
      [query[:filters], query[:group_bys]].each do |expression|
        expression.each do |term|
          attribute_mapping = mapping[term[0]]
          term[0] = attribute_mapping if attribute_mapping
        end
      end
      cost_query.save!
    end
  end
end
