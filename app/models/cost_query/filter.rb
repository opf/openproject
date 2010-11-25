require "set"

module CostQuery::Filter
  include Report::Filter

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
      CostQuery::Filter::IssueId,
      CostQuery::Filter::OverriddenCosts,
      CostQuery::Filter::PriorityId,
      CostQuery::Filter::ProjectId,
      CostQuery::Filter::SpentOn,
      CostQuery::Filter::StartDate,
      CostQuery::Filter::StatusId,
      CostQuery::Filter::Subject,
      CostQuery::Filter::TrackerId,
      #CostQuery::Filter::Tweek,
      #CostQuery::Filter::Tmonth,
      #CostQuery::Filter::Tyear,
      CostQuery::Filter::UpdatedOn,
      CostQuery::Filter::UserId,
      CostQuery::Filter::PermissionFilter,
      *CostQuery::Filter::CustomField.all
    ]
  end
end
