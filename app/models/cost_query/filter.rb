require "set"

module CostQuery::Filter
  def self.all
    @all ||= Set[
      CostQuery::Filter::ActivityId,
      CostQuery::Filter::AssignedToId,
      CostQuery::Filter::CategoryId,
      CostQuery::Filter::CostTypeId,
      CostQuery::Filter::FixedVersionId,
      CostQuery::Filter::IssueId,
      CostQuery::Filter::PriorityId,
      CostQuery::Filter::ProjectId,
      CostQuery::Filter::StatusId,
      CostQuery::Filter::TrackerId,
      CostQuery::Filter::UserId
      ]
  end

  def self.from_hash
    raise NotImplementedError
  end
end
