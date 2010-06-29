class CostQuery::Filter::FixedVersionId < CostQuery::Filter::Base
  null_operators
  join_table Issue

  def self.available_values(param={})
    Version.all.map { |a| [a.name, a.id] }
  end
end
