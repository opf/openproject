require "set"

module Report::Filter
  def self.all
    @all ||= Set[
      Report::Filter::ActivityId,
      Report::Filter::AssignedToId,
      Report::Filter::AuthorId,
      Report::Filter::CategoryId,
      Report::Filter::CostTypeId,
      Report::Filter::CreatedOn,
      Report::Filter::DueDate,
      Report::Filter::FixedVersionId,
      Report::Filter::IssueId,
      Report::Filter::OverriddenCosts,
      Report::Filter::PriorityId,
      Report::Filter::ProjectId,
      Report::Filter::SpentOn,
      Report::Filter::StartDate,
      Report::Filter::StatusId,
      Report::Filter::Subject,
      Report::Filter::TrackerId,
      #Report::Filter::Tweek,
      #Report::Filter::Tmonth,
      #Report::Filter::Tyear,
      Report::Filter::UpdatedOn,
      Report::Filter::UserId,
      Report::Filter::PermissionFilter,
      *Report::Filter::CustomField.all
    ]
  end

  def self.all_grouped
    all.group_by { |f| f.applies_for }.to_a.sort { |a,b| a.first.to_s <=> b.first.to_s }
  end

  def self.from_hash
    raise NotImplementedError
  end
end
