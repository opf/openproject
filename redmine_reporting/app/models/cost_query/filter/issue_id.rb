class CostQuery::Filter::IssueId < CostQuery::Filter::Base
  label :field_issue

  def self.available_values(*)
    issues = Project.visible.collect { |p| p.issues }.flatten.uniq.sort_by { |i| i.id }
    issues.map { |i| ["##{i.id} #{i.subject.length>30 ? i.subject.first(26)+'...': i.subject}", i.id] }
  end
end
