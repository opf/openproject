require "set"

module CostQuery::GroupBy
  def self.all
    @all ||= Set[
      CostQuery::GroupBy::ActivityId,
      CostQuery::GroupBy::CostObjectId,
      CostQuery::GroupBy::CostTypeId,
      CostQuery::GroupBy::IssueId,
      CostQuery::GroupBy::ProjectId,
      CostQuery::GroupBy::SpentOn,
      CostQuery::GroupBy::Tmonth,
      CostQuery::GroupBy::TrackerId,
      CostQuery::GroupBy::Tweek,
      CostQuery::GroupBy::Tyear,
      CostQuery::GroupBy::UserId
      ]
  end

  def self.all_grouped
    all.group_by { |g| g.applies_for }.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
  end

  def self.from_hash
    raise NotImplementedError
  end
end
