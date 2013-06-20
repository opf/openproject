class CostQuery::GroupBy::ProjectId < Report::GroupBy::Base

  def self.label
    Project.model_name.human
  end
end
