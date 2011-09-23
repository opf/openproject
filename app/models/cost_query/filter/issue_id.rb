class CostQuery::Filter::IssueId < CostQuery::Filter::Base
  label :field_issue

  def self.available_values(*)
    issues = Project.visible.collect { |p| p.issues }.flatten.uniq.sort_by { |i| i.id }
    issues.map { |i| [text_for_issue(i), i.id] }
  end

  def self.heavy?
    true
  end
  not_selectable! if heavy?

  ##
  # Overwrites Report::Filter::Base self.label_for_value method
  # to achieve a more performant implementation
  def self.label_for_value(value)
    return nil unless value.to_i.to_s == value.to_s # we expect an issue-id
    issue = Issue.find(value.to_i)
    [text_for_issue(issue), issue.id] if issue and issue.visible?(User.current)
  end

  def self.text_for_issue(i)
    i = i.first if i.is_a? Array
    str = "##{i.id} "
    str << (i.subject.length > 30 ? i.subject.first(26)+'...': i.subject)
  end

  def self.text_for_id(i)
    text_for_issue Issue.find(i)
  rescue ActiveRecord::RecordNotFound
    ""
  end
end
