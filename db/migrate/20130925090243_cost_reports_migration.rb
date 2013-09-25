class CostReportsMigration < ActiveRecord::Migration

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

  def migrate_cost_queries(&mapping)
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
